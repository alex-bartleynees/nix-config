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

  getResetSubvolumes = let
    # Function to check if a subvolume should never be reset
    isProtectedSubvolume = name:
      name == "@nix" || name == "@snapshots" || lib.hasInfix ".snapshots"
      name; # Protect any subvolume containing .snapshots

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
      # Function to check if a subvolume should never be reset
      isProtectedSubvolume = name:
        name == "@nix" || name == "@snapshots" || lib.hasInfix ".snapshots"
        name; # Protect any subvolume containing .snapshots

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
          grep = "${pkgs.gnugrep}/bin/grep";
          which = "${pkgs.which}/bin/which";
          lsblk = "${pkgs.util-linux}/bin/lsblk";
          btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
          find = "${pkgs.findutils}/bin/find";
          file = "${pkgs.file}/bin/file";
        };
        services.immutability = {
          description =
            "Factory resets BTRFS subvolumes that are marked for resetOnBoot. Intentionally preserved files are restored.";
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
            DEPTH=0
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
            echo "Environment variables:"
            env | grep -E "(PATH|HOME|USER)" || true
            echo "Available commands:"
            which btrfs mount umount mktemp mkdir rm cp || true
            echo "Disk devices:"
            ls -la /dev/disk/by-label/ || true
            echo "Block devices:"
            lsblk || true

            # Logger functions
            log() {
                local indent=""
                for ((i=0; i<DEPTH; i++)); do
                    indent="  $indent"
                done
                echo "[$(date '+%H:%M:%S')] $indent$*"
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

            trace() {
                local check=true
                local cmd=()
                
                # Parse arguments - if last arg is "nocheck", don't fail on error
                for arg in "$@"; do
                    if [[ "$arg" == "nocheck" ]]; then
                        check=false
                    else
                        cmd+=("$arg")
                    fi
                done
                
                ((DEPTH++))
                log "''${cmd[*]}"
                
                local output stderr_output
                if output=$(mktemp) && stderr_output=$(mktemp); then
                    local exit_code=0
                    "''${cmd[@]}" >"$output" 2>"$stderr_output" || exit_code=$?
                    
                    # Print stdout if not empty
                    if [[ -s "$output" ]]; then
                        while IFS= read -r line; do
                            log "$line"
                        done < "$output"
                    fi
                    
                    # Print stderr if not empty
                    if [[ -s "$stderr_output" ]]; then
                        while IFS= read -r line; do
                            warning "$line"
                        done < "$stderr_output"
                    fi
                    
                    rm -f "$output" "$stderr_output"
                    ((DEPTH--))
                    
                    if [[ $exit_code -ne 0 ]]; then
                        warning "Command failed with status $exit_code"
                        if [[ "$check" == true ]]; then
                            return $exit_code
                        fi
                    fi
                    
                    return $exit_code
                else
                    ((DEPTH--))
                    return 1
                fi
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
                    trace umount -R "$MOUNT_POINT" nocheck
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
                esac
            }

            btrfs_sync() {
                local path="$1"
                trace btrfs filesystem sync "$path"
            }

            btrfs_subvolume_delete() {
                local path="$1"
                if [[ -e "$path" ]]; then
                    trace btrfs subvolume delete "$path" --commit-after
                    btrfs_sync "$(dirname "$path")"
                fi
            }

            btrfs_subvolume_delete_recursively() {
                local path="$1"
                if [[ ! -e "$path" ]]; then
                    return 0
                fi
                
                # Check if this is actually a subvolume before trying to list child subvolumes
                if ! btrfs subvolume show "$path" >/dev/null 2>&1; then
                    warning "$path is not a subvolume, skipping"
                    return 0
                fi
                
                # Get list of child subvolumes
                local output
                if output=$(btrfs subvolume list -o "$path" 2>/dev/null); then
                    while IFS= read -r line; do
                        if [[ -n "$line" ]]; then
                            # Parse the subvolume path from the output
                            local subvol_path
                            subvol_path=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":"");}')
                            if [[ -n "$subvol_path" ]]; then
                                local full_path="$(dirname "$path")/$subvol_path"
                                btrfs_subvolume_delete_recursively "$full_path"
                            fi
                        fi
                    done <<< "$output"
                fi
                
                btrfs_subvolume_delete "$path"
            }

            btrfs_subvolume_snapshot() {
                local source="$1"
                local target="$2"
                local readonly="''${3:-false}"
                
                require_test "-d" "$source"
                btrfs_subvolume_delete_recursively "$target"
                
                local cmd=(btrfs subvolume snapshot)
                if [[ "$readonly" == "true" ]]; then
                    cmd+=(-r)
                fi
                cmd+=("$source" "$target")
                
                trace "''${cmd[@]}"
                btrfs_sync "$source"
                # Only sync target if the snapshot was created successfully
                if [[ -e "$target" ]]; then
                    btrfs_sync "$target"
                fi
            }

            btrfs_subvolume_rw() {
                local path="$1"
                trace btrfs property set -ts "$path" ro false
            }

            extract_persistent_files() {
                local subvolume_mount_point="$1"
                local paths_to_keep="$2"
                local source_subvolume="$3"
                local temp_dir="$4"
                
                local persistent_subvol="$temp_dir/persistent_files"
                
                # Create a minimal subvolume with just the persistent files
                trace btrfs subvolume create "$persistent_subvol"
                
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
                        local target_path="$persistent_subvol/$rel_path"
                        
                        if [[ -e "$source_path" ]]; then
                            # Create parent directories
                            mkdir -p "$(dirname "$target_path")"
                            
                            # Copy with attributes
                            trace cp -a "$source_path" "$target_path"
                        else
                            warning "Persistent path not found: $source_path"
                        fi
                    fi
                done
                
                echo "$persistent_subvol"
            }

            apply_persistent_files_via_send_receive() {
                local persistent_subvol="$1"
                local target_subvolume="$2"
                
                # First, create a readonly snapshot of the persistent files
                local persistent_snapshot="''${persistent_subvol}_snapshot"
                btrfs_subvolume_snapshot "$persistent_subvol" "$persistent_snapshot" true
                
                local stream_file
                stream_file=$(mktemp)
                
                # Generate send stream
                log "Generating send stream from $persistent_snapshot"
                if btrfs send "$persistent_snapshot" > "$stream_file" 2>/dev/null; then
                    # Apply the stream to target subvolume
                    log "Applying persistent files to $target_subvolume"
                    if btrfs receive "$target_subvolume" < "$stream_file" 2>/dev/null; then
                        log "Successfully applied persistent files via send/receive"
                        
                        # The receive creates a new subvolume, we need to merge it
                        local received_subvol="$target_subvolume/$(basename "$persistent_snapshot")"
                        if [[ -e "$received_subvol" ]]; then
                            trace cp -a "$received_subvol/." "$target_subvolume/"
                            btrfs_subvolume_delete "$received_subvol"
                        fi
                    else
                        error "btrfs receive failed"
                        warning "Falling back to direct file copy"
                        trace cp -a "$persistent_subvol/." "$target_subvolume/"
                    fi
                else
                    error "btrfs send failed"
                    warning "Falling back to direct file copy"
                    trace cp -a "$persistent_subvol/." "$target_subvolume/"
                fi
                
                rm -f "$stream_file"
                
                # Clean up the readonly snapshot
                btrfs_subvolume_delete "$persistent_snapshot"
            }

            mount_subvolumes() {
                local disk="$1"
                local mount_point="$2"
                local snapshots_subvolume="$3"
                shift 3
                local subvolume_names=("$@")
                
                debug "Mounting subvolumes from disk $disk to $mount_point"
                debug "Snapshots subvolume: $snapshots_subvolume"
                debug "Subvolume names: ''${subvolume_names[*]}"
                
                require_test "-b" "$disk"
                mkdir -p "$mount_point"
                debug "Created mount point: $mount_point"
                
                debug "Mounting root subvolume (subvolid=5)"
                debug "Mount command: mount -t btrfs -o subvolid=5,user_subvol_rm_allowed $disk $mount_point"
                
                # Try mount with explicit error handling
                if ! mount -t btrfs -o "subvolid=5,user_subvol_rm_allowed" "$disk" "$mount_point" 2>&1; then
                    error "Failed to mount root subvolume"
                    error "Checking disk status:"
                    ls -la "$disk" || true
                    lsblk | grep -E "(dm-0|crypted)" || true
                    abort "Cannot mount BTRFS root subvolume"
                fi
                debug "Root subvolume mounted successfully"
                
                debug "Listing available subvolumes:"
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
                        if ! trace mount -t btrfs -o "subvol=$subvolume_name,user_subvol_rm_allowed" "$disk" "$subvol_mount" nocheck; then
                            warning "Failed to mount subvolume $subvolume_name, continuing..."
                        else
                            debug "Successfully mounted $subvolume_name"
                        fi
                    else
                        warning "Subvolume $subvolume_name does not exist, skipping mount"
                    fi
                done
                
                debug "Mount operations completed, current mounts:"
                mount | grep "$mount_point" || warning "No mounts found for $mount_point"
            }

            unmount_subvolumes() {
                local mount_point="$1"
                trace umount -R "$mount_point" nocheck
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
                
                log "Starting btrfs send/receive impermanence reset for: ''${subvolume_names[*]}"
                log "Preserving paths: $paths_to_keep"
                
                # Set up cleanup trap
                debug "Setting up cleanup trap"
                trap cleanup EXIT ERR
                
                debug "About to call mount_subvolumes"
                mount_subvolumes "$disk" "$MOUNT_POINT" "$snapshots_subvolume_name" "''${subvolume_names[@]}"
                debug "mount_subvolumes completed successfully"
                
                for pair in "''${subvolume_pairs[@]}"; do
                    local subvolume_name="''${pair%%=*}"
                    local subvolume_mount_point="''${pair#*=}"
                    debug "Processing pair: $pair"
                    debug "Subvolume name: $subvolume_name"
                    debug "Mount point: $subvolume_mount_point"
                    log "Processing subvolume: $subvolume_name"
                    
                    local subvolume="$MOUNT_POINT/$subvolume_name"
                    local snapshots_dir="$MOUNT_POINT/$snapshots_subvolume_name/$subvolume_name"
                    
                    debug "Subvolume path: $subvolume"
                    debug "Snapshots directory: $snapshots_dir"
                    
                    local previous_snapshot="$snapshots_dir/PREVIOUS"
                    local penultimate_snapshot="$snapshots_dir/PENULTIMATE"
                    local fresh_snapshot="$snapshots_dir/FRESH"
                    
                    debug "Creating snapshots directory: $snapshots_dir"
                    mkdir -p "$snapshots_dir"
                    debug "Snapshots directory created successfully"
                    
                    # Create temporary directory for persistent file extraction
                    local temp_dir
                    debug "Creating temporary directory in $MOUNT_POINT"
                    temp_dir=$(mktemp -d -p "$MOUNT_POINT")
                    debug "Temporary directory created: $temp_dir"
                    
                    log "Extracting persistent files from current state"
                    debug "Calling extract_persistent_files with:"
                    debug "  - subvolume_mount_point: $subvolume_mount_point"
                    debug "  - paths_to_keep: $paths_to_keep"
                    debug "  - subvolume: $subvolume"
                    debug "  - temp_dir: $temp_dir"
                    local persistent_subvol
                    persistent_subvol=$(extract_persistent_files "$subvolume_mount_point" "$paths_to_keep" "$subvolume" "$temp_dir")
                    debug "extract_persistent_files returned: $persistent_subvol"
                    
                    # Rotate snapshots (keep history for debugging)
                    log "Rotating snapshots"
                    require_test "-d" "$subvolume"
                    if [[ -e "$previous_snapshot" ]]; then
                        debug "Previous snapshot exists, rotating to penultimate"
                        btrfs_subvolume_snapshot "$previous_snapshot" "$penultimate_snapshot"
                    else
                        debug "No previous snapshot found, skipping rotation"
                    fi
                    debug "Creating new previous snapshot from current subvolume"
                    btrfs_subvolume_snapshot "$subvolume" "$previous_snapshot" true
                    
                    # Create completely fresh empty subvolume
                    log "Creating fresh empty subvolume"
                    debug "Deleting any existing fresh snapshot at: $fresh_snapshot"
                    btrfs_subvolume_delete_recursively "$fresh_snapshot"
                    debug "Creating fresh subvolume at: $fresh_snapshot"
                    trace btrfs subvolume create "$fresh_snapshot"
                    
                    # Apply persistent files to the fresh subvolume
                    log "Applying persistent files to fresh subvolume"
                    apply_persistent_files_via_send_receive "$persistent_subvol" "$fresh_snapshot"
                    
                    # Replace current subvolume with fresh one
                    log "Replacing subvolume with fresh snapshot"
                    btrfs_subvolume_delete_recursively "$subvolume"
                    btrfs_subvolume_snapshot "$fresh_snapshot" "$subvolume"
                    
                    # Clean up the fresh snapshot (we don't need to keep it)
                    btrfs_subvolume_delete "$fresh_snapshot"
                    
                    # Clean up temporary directory
                    rm -rf "$temp_dir"
                    
                    log "Completed processing $subvolume_name"
                done
                
                debug "About to unmount subvolumes"
                unmount_subvolumes "$MOUNT_POINT"
                debug "Subvolumes unmounted successfully"
                
                log "Btrfs send/receive impermanence reset completed successfully"
                echo "=== IMMUTABILITY SERVICE COMPLETED SUCCESSFULLY - $(date) ==="
            }

            # Run main function with all arguments
            main "$@" 

          '';
        };
      };
    };

    # Critical: Auto-rebuild NixOS configuration early in boot process
    # systemd.services.nixos-auto-rebuild = {
    #   description = "Auto-rebuild NixOS configuration after impermanence reset";
    #   wantedBy = [ "multi-user.target" ];
    #   # Run after basic filesystem setup but before user services
    #   after = [ "local-fs.target" "systemd-remount-fs.service" ];
    #   before = [
    #     "display-manager.service"
    #     "getty@tty1.service"
    #     "systemd-user-sessions.service" # Blocks user logins until complete
    #   ];
    #   unitConfig = {
    #     DefaultDependencies = false;
    #     ConditionPathExists = "/tmp/.nixos-needs-rebuild";
    #   };
    #   serviceConfig = {
    #     Type = "oneshot";
    #     RemainAfterExit = true;
    #     StandardOutput = "journal";
    #     StandardError = "journal";
    #     # Ensure we have a clean environment
    #     Environment = [
    #       "HOME=/root"
    #       "USER=root"
    #       "PATH=${lib.makeBinPath [ pkgs.nixos-rebuild pkgs.git pkgs.nix ]}"
    #     ];
    #     ExecStart = pkgs.writeScript "auto-rebuild" ''
    #       #!/bin/bash
    #       set -euo pipefail
    #
    #       echo "=== NixOS Auto-Rebuild Starting ==="
    #       echo "System was reset, rebuilding declarative configuration..."
    #
    #       # Check for host identifier to determine which flake target to build
    #       if [ -f /etc/hostname-for-rebuild ]; then
    #         HOST=$(cat /etc/hostname-for-rebuild)
    #         echo "Building for host: $HOST"
    #         
    #         # Use the home flake configuration
    #         cd /home/alexbn/.config/nix-config
    #         if nixos-rebuild switch --flake ".#$HOST" --install-bootloader; then
    #           echo "=== NixOS rebuild completed successfully ==="
    #           rm -f /tmp/.nixos-needs-rebuild
    #         else
    #           echo "=== NixOS rebuild failed! ==="
    #           echo "Manual intervention may be required."
    #           exit 1
    #         fi
    #       else
    #         echo "ERROR: /etc/hostname-for-rebuild not found!"
    #         echo "Please create this file with your host name (e.g., 'echo thinkpad | sudo tee /etc/hostname-for-rebuild')"
    #         exit 1
    #       fi
    #     '';
    #     # If rebuild fails, don't block the boot process entirely
    #     # but log the failure clearly
    #     ExecStartPost = pkgs.writeScript "rebuild-cleanup" ''
    #       #!/bin/bash
    #       if [ -f /tmp/.nixos-needs-rebuild ]; then
    #         echo "WARNING: NixOS rebuild failed, system may not be properly configured!"
    #         echo "Run 'sudo nixos-rebuild switch' manually when possible."
    #         # Create a prominent warning file
    #         echo "NixOS rebuild failed on $(date)" > /etc/REBUILD_FAILED_WARNING
    #       fi
    #     '';
    #   };
    # };

    # Ensure the rebuild service blocks user sessions
    # systemd.services."systemd-user-sessions".after =
    #   [ "nixos-auto-rebuild.service" ];
    #
    # # Alternative: If you want to be even more aggressive, prevent all logins until rebuild completes
    # systemd.services."getty@".after = [ "nixos-auto-rebuild.service" ];
    # systemd.services."serial-getty@".after = [ "nixos-auto-rebuild.service" ];
    #
    # # Prevent SSH logins until rebuild is complete (if using SSH)
    # systemd.services."sshd".after = [ "nixos-auto-rebuild.service" ];

    # Enhanced management script
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "nixos-impermanence" ''
        #!/bin/bash
        set -euo pipefail

        usage() {
          echo "Usage: $0 <command> [options]"
          echo "Commands:"
          echo "  status                    Show impermanence status"
          echo "  check-rebuild            Check if rebuild is needed"
          echo "  force-rebuild            Force a rebuild now"
          echo "  list-snapshots           List available snapshots"
          echo "  simulate-reset           Test the reset process"
        }

        case "$''${1:-}" in
          status)
            echo "=== NixOS Impermanence Status ==="
            if [ -f /tmp/.nixos-needs-rebuild ]; then
              echo "⚠️  System reset detected, rebuild pending"
            else
              echo "✓ System in normal state"
            fi
            
            if [ -f /etc/REBUILD_FAILED_WARNING ]; then
              echo "❌ Last rebuild failed!"
              cat /etc/REBUILD_FAILED_WARNING
            fi
            
            systemctl status nixos-auto-rebuild.service --no-pager || true
            ;;
            
          check-rebuild)
            if [ -f /tmp/.nixos-needs-rebuild ]; then
              echo "Rebuild needed"
              exit 1
            else
              echo "No rebuild needed"
              exit 0
            fi
            ;;
            
          force-rebuild)
            echo "Forcing NixOS rebuild..."
            touch /tmp/.nixos-needs-rebuild
            systemctl start nixos-auto-rebuild.service
            ;;
            
          simulate-reset)
            echo "Simulating system reset..."
            touch /tmp/.nixos-needs-rebuild
            echo "✓ Reset marker created"
            echo "Run 'systemctl start nixos-auto-rebuild.service' to test rebuild"
            ;;
            
          list-snapshots)
            echo "=== Available Snapshots ==="
            if [ -d /.snapshots ]; then
              find /.snapshots -name "PREVIOUS" -o -name "PENULTIMATE" | sort
            else
              echo "No snapshots directory found"
            fi
            ;;
            
          *)
            usage
            exit 1
            ;;
        esac
      '')
    ];
  };
}
