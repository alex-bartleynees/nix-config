{ config, lib, pkgs, ... }:
let
  # Find BTRFS filesystem by label 
  device = "/dev/disk/by-label/nixos";

  # Use standard crypted device name since we're using nixos label
  luksDeviceName = "crypted";
  deviceDependency = "dev-mapper-${luksDeviceName}.device";
  snapshotsSubvolumeName = "@snapshots";

  pathsToKeep =
    ''"${lib.strings.concatStringsSep " " config.impermanence.persistPaths}"'';

  # Use configured subvolumes instead of trying to extract from disko
  subvolumes = config.impermanence.subvolumes;

  # Function to check if a subvolume should never be reset
  isProtectedSubvolume = name:
    name == "@nix" || name == "@snapshots" || lib.hasInfix ".snapshots" name;

  getResetSubvolumes = let
    resetSubvols = lib.filterAttrs (name: subvol:
      # If resetSubvolumes is empty, reset all except protected subvolumes
      # Otherwise only reset specified subvolumes (but still protect critical ones)
      if config.impermanence.resetSubvolumes == [ ] then
        !isProtectedSubvolume name
      else
        lib.elem name config.impermanence.resetSubvolumes
        && !isProtectedSubvolume name) subvolumes;
  in lib.strings.concatStringsSep " "
  (lib.mapAttrsToList (name: subvol: "${name}=${subvol.mountpoint}")
    resetSubvols);

  subvolumeNameMountPointPairs = ''"${getResetSubvolumes}"'';

in {
  # Define the impermanence options
  options.impermanence = {
    enable =
      lib.mkEnableOption "Enable BTRFS impermanence with automatic reset";

    persistPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/etc/sops"
        "/etc/ssh" # SSH host keys
        "/var/log" # System logs
        "/var/lib/nixos" # NixOS state
        "/var/lib/systemd/random-seed" # Random seed for reproducibility
      ];
      description = "Paths to persist across impermanence resets";
    };

    resetSubvolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ]; # Empty list means reset all except protected subvolumes
      description =
        "List of subvolume names to reset. Empty list resets all except @nix, @snapshots, and any subvolume containing '.snapshots' (which should never be reset).";
    };

    subvolumes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          mountpoint = lib.mkOption {
            type = lib.types.str;
            description = "Mount point for the subvolume";
          };
        };
      });
      default = { };
      example = {
        "@home" = { mountpoint = "/home"; };
        "@var" = { mountpoint = "/var"; };
        "@tmp" = { mountpoint = "/tmp"; };
      };
      description = "Subvolumes configuration with their mount points";
    };

  };

  config = lib.mkIf (config.impermanence.enable && subvolumes != { }) {
    # Mark reset subvolumes as needed for boot
    fileSystems = lib.mkMerge (let
      resetSubvols = lib.filterAttrs (name: subvol:
        # If resetSubvolumes is empty, reset all except protected subvolumes
        # Otherwise only reset specified subvolumes (but still protect critical ones)
        if config.impermanence.resetSubvolumes == [ ] then
          !isProtectedSubvolume name
        else
          lib.elem name config.impermanence.resetSubvolumes
          && !isProtectedSubvolume name) subvolumes;
    in lib.mapAttrsToList
    (name: subvol: { "${subvol.mountpoint}".neededForBoot = lib.mkForce true; })
    resetSubvols);

    boot.nixStoreMountOpts = [ "ro" ]; # Mount Nix store read-only
    boot.tmp.useTmpfs = true;

    boot.initrd = {
      supportedFilesystems = [ "btrfs" ];
      systemd = {
        enable = true;
        extraBin = {
          btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
          find = "${pkgs.findutils}/bin/find";
          file = "${pkgs.file}/bin/file";
          awk = "${pkgs.gawk}/bin/awk";
        };
        services.immutability = {
          description =
            "Factory resets BTRFS subvolumes. Intentionally preserved files are restored.";
          wantedBy = [ "initrd.target" ];
          requires = [ deviceDependency ];
          after =
            [ "systemd-cryptsetup@${luksDeviceName}.service" deviceDependency ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          scriptArgs =
            "${device} ${snapshotsSubvolumeName} ${subvolumeNameMountPointPairs} ${pathsToKeep}";
          script = ''
                          #!/bin/bash

            set -euo pipefail

            # Global variables
            MOUNT_POINT="/tmp/btrfs-immutable"

            # Enable debug logging (try multiple locations for persistence)
            DEBUG_LOG="/tmp/immutability-debug.log"
            if [[ -w "/var/log" ]]; then
                DEBUG_LOG="/var/log/immutability-debug.log"
            elif [[ -w "/run" ]]; then
                DEBUG_LOG="/run/immutability-debug.log"
            fi
            exec > >(tee -a "$DEBUG_LOG") 2>&1
            echo "=== IMMUTABILITY SERVICE DEBUG LOG - $(date) ==="
            echo "Script started with arguments: $*"

            # Logger functions
            log() {
                echo "[$(date '+%H:%M:%S')] $*"
            }

            warning() {
                log "WRN $*" >&2
            }

            error() {
                log "ERR $*" >&2
            }

            debug() {
                log "DBG $*"
            }

            abort() {
                error "$1"
                error "Unmounting and quitting"
                error "Debug log saved to $DEBUG_LOG"
                cleanup
                exit 1
            }

            cleanup() {
                if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
                    umount -R "$MOUNT_POINT" 2>/dev/null || true
                    rm -rf "$MOUNT_POINT"
                fi
            }

            require_test() {
                local condition="$1"
                local path="$2"
                
                debug "Checking requirement: $condition $path"
                case "$condition" in
                    "-d")
                        if [[ ! -d "$path" ]]; then
                            error "Directory check failed for: $path"
                            ls -la "$(dirname "$path")" || true
                            abort "Required directory does not exist: $path"
                        fi
                        debug "Directory check passed: $path"
                        ;;
                    "-b")
                        if [[ ! -b "$path" ]]; then
                            error "Block device check failed for: $path"
                            ls -la "$path" || true
                            file "$path" || true
                            abort "Required block device does not exist: $path"
                        fi
                        debug "Block device check passed: $path"
                        ;;
                    *)
                        error "Unknown condition: $condition"
                        abort "Invalid condition in require_test: $condition"
                        ;;
                esac
            }

            btrfs_sync() {
                local path="$1"
                btrfs filesystem sync "$path"
            }

            btrfs_subvolume_delete() {
                local path="$1"
                if [[ -e "$path" ]]; then
                    debug "Attempting to delete subvolume: $path"
                    if ! btrfs subvolume delete "$path" --commit-after 2>/dev/null; then
                        warning "Failed to delete subvolume $path - may have nested subvolumes"
                        # Try to list what's preventing deletion
                        debug "Contents of $path:"
                        ls -la "$path" 2>/dev/null || true
                        debug "Child subvolumes of $path:"
                        btrfs subvolume list -o "$path" 2>/dev/null || true
                        return 1
                    fi
                    debug "Successfully deleted subvolume: $path"
                fi
            }

            btrfs_subvolume_delete_recursively() {
                local path="$1"
                if [[ ! -e "$path" ]]; then
                    return 0
                fi
                
                # Skip snapshot-related paths to avoid deleting snapshots themselves
                local basename_path=$(basename "$path")
                if [[ "$basename_path" == "@snapshots" || "$basename_path" == ".snapshots" ]]; then
                    debug "Skipping snapshot directory: $path"
                    return 0
                fi
                
                # Check if this is actually a subvolume
                if ! btrfs subvolume show "$path" >/dev/null 2>&1; then
                    warning "$path is not a subvolume, skipping"
                    return 0
                fi
                
                debug "Processing subvolume for deletion: $path"
                
                # First, clean out all non-subvolume contents
                if [[ -d "$path" ]]; then
                    debug "Cleaning non-subvolume contents from: $path"
                    find "$path" -mindepth 1 -maxdepth 1 | while read -r item; do
                        if [[ -e "$item" ]]; then
                            # Check if this item is a btrfs subvolume
                            if btrfs subvolume show "$item" >/dev/null 2>&1; then
                                debug "Found child subvolume, skipping: $item"
                                # Skip child subvolumes - they will prevent parent deletion
                                continue
                            else
                                debug "Removing non-subvolume item: $item"
                                rm -rf "$item" 2>/dev/null || warning "Failed to remove $item"
                            fi
                        fi
                    done
                fi
                
                # Get list of child subvolumes that need to be deleted first
                local output
                debug "Checking for child subvolumes of: $path"
                if output=$(btrfs subvolume list -o "$path" 2>/dev/null); then
                    debug "Found child subvolumes, deleting them first"
                    while IFS= read -r line; do
                        if [[ -n "$line" ]]; then
                            # Parse the subvolume path from the output
                            local subvol_path
                            subvol_path=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":"");}')
                            if [[ -n "$subvol_path" ]]; then
                                # Skip snapshot-related child subvolumes (but allow FRESH subdirectories)
                                local subvol_basename=$(basename "$subvol_path")
                                if [[ "$subvol_basename" == "@snapshots" || "$subvol_basename" == ".snapshots" ]]; then
                                    debug "Skipping snapshot child subvolume: $subvol_path"
                                    continue
                                fi
                                
                                # The subvol_path is relative to filesystem root
                                local full_path="$MOUNT_POINT/$subvol_path"
                                debug "Recursively deleting child subvolume: $full_path"
                                btrfs_subvolume_delete_recursively "$full_path"
                            fi
                        fi
                    done <<< "$output"
                fi

                # Now try to delete the parent subvolume (should be empty now)
                debug "Attempting to delete now-empty subvolume: $path"
                if ! btrfs_subvolume_delete "$path"; then
                    warning "Failed to delete $path, checking what's left"
                    ls -la "$path" 2>/dev/null || true
                    btrfs subvolume list -o "$path" 2>/dev/null || true
                fi
            }

            btrfs_subvolume_rw() {
                local path="$1"
                btrfs property set -ts "$path" ro false
            }

            extract_persistent_files() {
                local subvolume_mount_point="$1"
                local paths_to_keep="$2"
                local source_subvolume="$3"
                local fresh_snapshot="$4"
                
                # Fresh snapshot should already be created by caller
                debug "Using fresh snapshot for extraction: $fresh_snapshot" >&2
                
                # Convert paths_to_keep string to array
                local -a paths_array
                IFS=' ' read -ra paths_array <<< "$paths_to_keep"
                
                # Copy only the persistent files/directories that belong to this subvolume
                for path_to_keep in "''${paths_array[@]}"; do
                    # Check if this path belongs to the current subvolume's mount point
                    local path_belongs_to_subvol=false
                    
                    if [[ "$subvolume_mount_point" == "/" ]]; then
                        # For root subvolume, only handle paths that don't belong to other subvolumes
                        # Exclude /home paths which belong to @home subvolume
                        if [[ "$path_to_keep" != "/home/"* ]]; then
                            path_belongs_to_subvol=true
                        fi
                    elif [[ "$path_to_keep" == "$subvolume_mount_point/"* ]]; then
                        # For non-root subvolumes, handle paths that start with the mount point
                        path_belongs_to_subvol=true
                    fi
                    
                    if [[ "$path_belongs_to_subvol" == true ]]; then
                        local rel_path="''${path_to_keep#$subvolume_mount_point}"
                        rel_path="''${rel_path#/}"
                        local source_path="$source_subvolume/$rel_path"
                        local target_path="$fresh_snapshot/$rel_path"
                        
                        if [[ -e "$source_path" ]]; then
                            # Create parent directories with correct ownership
                            local current_path="$fresh_snapshot"
                            local remaining_path="$rel_path"
                            
                            # Build path piece by piece, setting ownership for each level
                            while [[ "$remaining_path" == */* ]]; do
                                local next_part="''${remaining_path%%/*}"
                                current_path="$current_path/$next_part"
                                remaining_path="''${remaining_path#*/}"
                                
                                if [[ ! -d "$current_path" ]]; then
                                    mkdir "$current_path"
                                    # Set ownership to match the corresponding source directory
                                    local source_parent="$source_subvolume/''${current_path#$fresh_snapshot/}"
                                    if [[ -d "$source_parent" ]]; then
                                        local src_uid src_gid
                                        src_uid=$(stat -c %u "$source_parent")
                                        src_gid=$(stat -c %g "$source_parent")
                                        chown "$src_uid:$src_gid" "$current_path"
                                    fi
                                fi
                            done
                            
                            # Copy with all attributes preserved
                            if [[ -d "$source_path" ]]; then
                                # It's a directory - copy contents
                                if cp -a --preserve=all --reflink=auto "$source_path/." "$target_path/" 2>/dev/null; then
                                    debug "Copied directory: $source_path -> $target_path" >&2
                                else
                                    warning "Failed to copy directory: $source_path -> $target_path" >&2
                                fi
                            else
                                # It's a file - copy the file itself
                                if cp -a --preserve=all --reflink=auto "$source_path" "$target_path" 2>/dev/null; then
                                    debug "Copied file: $source_path -> $target_path" >&2
                                else
                                    warning "Failed to copy file: $source_path -> $target_path" >&2
                                fi
                            fi
                        else
                            warning "Persistent path not found: $source_path" >&2
                        fi
                    fi
                done
                
                echo "$fresh_snapshot"
            }

            clear_subvolume_contents() {
                local subvolume="$1"
                local paths_to_keep="$2"
                
                debug "Clearing contents of subvolume: $subvolume"
                debug "Paths to preserve: $paths_to_keep"
                
                if [[ ! -d "$subvolume" ]]; then
                    warning "Subvolume directory does not exist: $subvolume"
                    return 1
                fi
                
                local -a paths_array
                IFS=' ' read -ra paths_array <<< "$paths_to_keep"
                
                # Critical directories/files to always preserve 
                local -a critical_paths=(
                    "nix"
                    ".snapshots"
                    "@snapshots"
                    "boot"
                )
                
                debug "Critical paths to preserve: ''${critical_paths[*]}"
                
                # First handle systemd-created subvolumes in /var specifically
                if [[ "$subvolume" == *"@var"* ]] || [[ "$subvolume" == */var ]] || [[ -d "$subvolume/var" ]]; then
                    debug "Handling systemd subvolumes in var directory"
                    local systemd_subvols=(
                        "$subvolume/var/lib/portables"
                        "$subvolume/var/lib/machines"
                    )
                    
                    for systemd_subvol in "''${systemd_subvols[@]}"; do
                        if [[ -e "$systemd_subvol" ]] && btrfs subvolume show "$systemd_subvol" >/dev/null 2>&1; then
                            debug "Found systemd subvolume, deleting: $systemd_subvol"
                            if ! btrfs subvolume delete "$systemd_subvol" --commit-after 2>/dev/null; then
                                warning "Failed to delete systemd subvolume: $systemd_subvol"
                                # Try to force delete if regular delete fails
                                btrfs subvolume delete "$systemd_subvol" 2>/dev/null || warning "Force delete also failed for: $systemd_subvol"
                            else
                                debug "Successfully deleted systemd subvolume: $systemd_subvol"
                            fi
                        fi
                    done
                fi
                
                # Remove all contents except critical paths
                find "$subvolume" -mindepth 1 -maxdepth 1 | while read -r item; do
                    local basename_item=$(basename "$item")
                    local should_preserve=false
                    
                    # Check if this item should be preserved
                    for critical_path in "''${critical_paths[@]}"; do
                        if [[ "$basename_item" == "$critical_path" ]]; then
                            should_preserve=true
                            break
                        fi
                    done
                    
                    # Check if this is a btrfs subvolume that needs special handling
                    if [[ -d "$item" ]] && btrfs subvolume show "$item" >/dev/null 2>&1; then
                        debug "Found btrfs subvolume during cleanup: $item"
                        if [[ "$should_preserve" == true ]]; then
                            debug "Preserving critical subvolume: $item"
                        else
                            debug "Deleting non-critical subvolume: $item"
                            if ! btrfs subvolume delete "$item" --commit-after 2>/dev/null; then
                                warning "Failed to delete subvolume $item, trying recursive deletion"
                                btrfs_subvolume_delete_recursively "$item"
                            else
                                debug "Successfully deleted subvolume: $item"
                            fi
                        fi
                    elif [[ "$should_preserve" == true ]]; then
                        debug "Preserving critical path: $item"
                    else
                        debug "Removing non-critical item: $item"
                        if [[ -d "$item" ]]; then
                            rm -rf "$item" 2>/dev/null || warning "Failed to remove directory: $item"
                        else
                            rm -f "$item" 2>/dev/null || warning "Failed to remove file: $item"
                        fi
                    fi
                done
                
                debug "Subvolume contents cleared successfully"
            }

            copy_persistent_files() {
                local persistent_subvol="$1"
                local target_subvolume="$2"

                debug "Apply persistent files to fresh"
                debug "Source: $persistent_subvol"
                debug "Target: $target_subvolume"
                
                # Check if persistent subvolume has any content
                local file_count
                file_count=$(find "$persistent_subvol" -type f 2>/dev/null | wc -l)
                debug "Found $file_count files in persistent subvolume"
                
                if [[ $file_count -eq 0 ]]; then
                    log "No persistent files to transfer, skipping"
                    return 0
                fi
                
                # Skip the complex send/receive and just use direct copy for now
                log "Using direct file copy to transfer persistent files"
                
                if [[ -d "$persistent_subvol" && -d "$target_subvolume" ]]; then
                    if cp -a --preserve=all --reflink=auto "$persistent_subvol/." "$target_subvolume/"; then
                        log "Successfully copied persistent files"
                    else
                        error "Failed to copy persistent files"
                        return 1
                    fi
                else
                    error "Source or target directory does not exist"
                    error "Source exists: $([[ -d "$persistent_subvol" ]] && echo "yes" || echo "no")"
                    error "Target exists: $([[ -d "$target_subvolume" ]] && echo "yes" || echo "no")"
                    return 1
                fi
            }

            mount_subvolumes() {
                local disk="$1"
                local mount_point="$2"
                local snapshots_subvolume="$3"
                shift 3
                local subvolume_names=("$@")
                
                require_test "-b" "$disk"
                mkdir -p "$mount_point"
                
                if ! mount -t btrfs -o "subvolid=5,user_subvol_rm_allowed" "$disk" "$mount_point" 2>&1; then
                    error "Failed to mount root subvolume"
                    abort "Cannot mount BTRFS root subvolume"
                fi
                debug "Root subvolume mounted successfully"
                
                btrfs subvolume list "$mount_point" || warning "Could not list subvolumes"
                
                # Mount all subvolumes including snapshots
                local all_subvolumes=("''${subvolume_names[@]}" "$snapshots_subvolume")
                debug "All subvolumes to mount: ''${all_subvolumes[*]}"
                
                for subvolume_name in "''${all_subvolumes[@]}"; do
                    local subvol_mount="$mount_point/$subvolume_name"
                    debug "Mounting subvolume $subvolume_name to $subvol_mount"
                    mkdir -p "$subvol_mount"
                    
                    # Check if subvolume exists before trying to mount
                    if btrfs subvolume show "$mount_point/$subvolume_name" >/dev/null 2>&1; then
                        debug "Subvolume $subvolume_name exists, mounting..."
                        if ! mount -t btrfs -o "subvol=$subvolume_name,user_subvol_rm_allowed" "$disk" "$subvol_mount" 2>/dev/null; then
                            warning "Failed to mount subvolume $subvolume_name, continuing..."
                        else
                            debug "Successfully mounted $subvolume_name"
                        fi
                    else
                        warning "Subvolume $subvolume_name does not exist, skipping mount"
                    fi
                done
                
                debug "Mount operations completed"
            }

            unmount_subvolumes() {
                local mount_point="$1"
                umount -R "$mount_point" 2>/dev/null || true
                rm -rf "$mount_point"
            }

            main() {
                debug "Main function called with $# arguments"
                
                if [[ $# -ne 4 ]]; then
                    error "Invalid number of arguments: $#"
                    error "Arguments received: $*"
                    abort "Usage: $0 <disk> <snapshots_subvolume> <subvol_pairs> <paths_to_keep>"
                fi
                
                local disk="$1"
                local snapshots_subvolume_name="$2"
                local subvolume_pairs_str="$3"
                local paths_to_keep_str="$4"
                
                debug "Disk: $disk"
                debug "Snapshots subvolume: $snapshots_subvolume_name"
                debug "Subvolume pairs string: $subvolume_pairs_str"
                debug "Paths to keep string: $paths_to_keep_str"
                
                # Convert space-separated strings to arrays
                local -a subvolume_pairs subvolume_names
                IFS=' ' read -ra subvolume_pairs <<< "$subvolume_pairs_str"
                debug "Parsed subvolume pairs: ''${subvolume_pairs[*]}"
                
                # Extract subvolume names from pairs
                for pair in "''${subvolume_pairs[@]}"; do
                    subvolume_names+=("''${pair%%=*}")
                done
                debug "Extracted subvolume names: ''${subvolume_names[*]}"
                
                # Sort paths to keep
                local paths_to_keep
                paths_to_keep=$(echo "$paths_to_keep_str" | tr ' ' '\n' | sort | tr '\n' ' ')
                paths_to_keep="''${paths_to_keep% }"  # Remove trailing space
                debug "Sorted paths to keep: $paths_to_keep"
                
                log "Starting impermanence reset for: ''${subvolume_names[*]}"
                log "Preserving paths: $paths_to_keep"
                
                # Set up cleanup trap
                trap cleanup EXIT ERR
                
                mount_subvolumes "$disk" "$MOUNT_POINT" "$snapshots_subvolume_name" "''${subvolume_names[@]}"
                
                for pair in "''${subvolume_pairs[@]}"; do
                    local subvolume_name="''${pair%%=*}"
                    local subvolume_mount_point="''${pair#*=}"
                    log "Processing subvolume: $subvolume_name"
                    
                    local subvolume="$MOUNT_POINT/$subvolume_name"
                    local snapshots_dir="$MOUNT_POINT/$snapshots_subvolume_name/$subvolume_name"
                    
                    local fresh_snapshot="$snapshots_dir/FRESH"
                    
                    mkdir -p "$snapshots_dir"
                    
                    # Create completely fresh empty subvolume first
                    log "Creating fresh empty subvolume"
                    btrfs_subvolume_delete_recursively "$fresh_snapshot"
                    mkdir -p "$(dirname "$fresh_snapshot")"
                    btrfs subvolume create "$fresh_snapshot"
                    
                    # Extract persistent files directly to the fresh subvolume
                    log "Extracting persistent files directly to fresh subvolume"
                    extract_persistent_files "$subvolume_mount_point" "$paths_to_keep" "$subvolume" "$fresh_snapshot"
                    
                    # Clear contents of current 
                    log "Clearing contents of subvolume while preserving structure"
                    clear_subvolume_contents "$subvolume" "$paths_to_keep"
                    
                    # Copy fresh contents back
                    log "Copying fresh contents to cleared subvolume"
                    copy_persistent_files "$fresh_snapshot" "$subvolume"
                    
                    # Clean up the fresh snapshot 
                    btrfs_subvolume_delete "$fresh_snapshot"
                    
                    log "Completed processing $subvolume_name"
                done
                
                unmount_subvolumes "$MOUNT_POINT"
                
                log "Btrfs impermanence reset completed successfully"
                echo "=== IMMUTABILITY SERVICE COMPLETED SUCCESSFULLY - $(date) ==="
            }

            # Run main function with all arguments
            main "$@" 

          '';
        };
      };
    };
  };
}
