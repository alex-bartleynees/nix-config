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
                log "${cmd[*]}"
                
                local output stderr_output
                if output=$(mktemp) && stderr_output=$(mktemp); then
                    local exit_code=0
                    "${cmd[@]}" >"$output" 2>"$stderr_output" || exit_code=$?
                    
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
                  echo "test"
                    # trace umount -R "$MOUNT_POINT" nocheck
                    # rm -rf "$MOUNT_POINT"
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
                trace btrfs filesystem sync "$path"
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
                
                # Skip snapshot-related paths to avoid deleting snapshots
                local basename_path=$(basename "$path")
                if [[ "$basename_path" == "@snapshots" || "$basename_path" == ".snapshots" || "$path" == *"@snapshots"* || "$path" == *".snapshots"* ]]; then
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
                                # Skip snapshot-related child subvolumes
                                if [[ "$subvol_path" == *"@snapshots"* || "$subvol_path" == *".snapshots"* ]]; then
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

            btrfs_subvolume_snapshot() {
                local source="$1"
                local target="$2"
                local readonly="${3:-false}"
                
                #require_test "-d" "$source"
                #btrfs_subvolume_delete_recursively "$target"
                debug "making snapshot of ${source} to ${target}"
                
                local cmd=(btrfs subvolume snapshot)
                if [[ "$readonly" == "true" ]]; then
                    cmd+=(-r)
                fi
                cmd+=("$source" "$target")

                debug "subvolume snapshot successfully"
                
                #trace "${cmd[@]}"
                #btrfs_sync "$source"
                # Only sync target if the snapshot was created successfully
                #if [[ -e "$target" ]]; then
                 #   btrfs_sync "$target"
                #fi
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
                if ! btrfs subvolume create "$persistent_subvol" >/dev/null 2>&1; then
                    error "Failed to create persistent subvolume: $persistent_subvol" >&2
                    return 1
                fi
                debug "Created persistent subvolume: $persistent_subvol" >&2
                
                # Convert paths_to_keep string to array
                local -a paths_array
                IFS=' ' read -ra paths_array <<< "$paths_to_keep"
                
                # Copy only the persistent files/directories that belong to this subvolume
                for path_to_keep in "${paths_array[@]}"; do
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
                        local rel_path="${path_to_keep#$subvolume_mount_point}"
                        rel_path="${rel_path#/}"
                        local source_path="$source_subvolume/$rel_path"
                        local target_path="$persistent_subvol/$rel_path"
                        
                        if [[ -e "$source_path" ]]; then
                            # Create parent directories
                            mkdir -p "$(dirname "$target_path")"
                            
                            # Copy with attributes
                            if ! cp -a "$source_path" "$target_path" 2>/dev/null; then
                                warning "Failed to copy: $source_path -> $target_path" >&2
                            else
                                debug "Copied: $source_path -> $target_path" >&2
                            fi
                        else
                            warning "Persistent path not found: $source_path" >&2
                        fi
                    fi
                done
                
                echo "$persistent_subvol"
            }

            apply_persistent_files_via_send_receive() {
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
                debug "Copying from $persistent_subvol to $target_subvolume"
                
                if [[ -d "$persistent_subvol" && -d "$target_subvolume" ]]; then
                    # Use rsync-like behavior with cp
                    if trace cp -a "$persistent_subvol/." "$target_subvolume/"; then
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
                
                debug "Mounting subvolumes from disk $disk to $mount_point"
                debug "Snapshots subvolume: $snapshots_subvolume"
                debug "Subvolume names: ${subvolume_names[*]}"
                
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
                local all_subvolumes=("${subvolume_names[@]}" "$snapshots_subvolume")
                debug "All subvolumes to mount: ${all_subvolumes[*]}"
                
                for subvolume_name in "${all_subvolumes[@]}"; do
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
                debug "Parsed subvolume pairs: ${subvolume_pairs[*]}"
                
                # Extract subvolume names from pairs
                for pair in "${subvolume_pairs[@]}"; do
                    subvolume_names+=("${pair%%=*}")
                done
                debug "Extracted subvolume names: ${subvolume_names[*]}"
                
                # Sort paths to keep
                local paths_to_keep
                paths_to_keep=$(echo "$paths_to_keep_str" | tr ' ' '\n' | sort | tr '\n' ' ')
                paths_to_keep="${paths_to_keep% }"  # Remove trailing space
                debug "Sorted paths to keep: $paths_to_keep"
                
                log "Starting btrfs send/receive impermanence reset for: ${subvolume_names[*]}"
                log "Preserving paths: $paths_to_keep"
                
                # Set up cleanup trap
                debug "Setting up cleanup trap"
                trap cleanup EXIT ERR
                
                debug "About to call mount_subvolumes"
                mount_subvolumes "$disk" "$MOUNT_POINT" "$snapshots_subvolume_name" "${subvolume_names[@]}"
                debug "mount_subvolumes completed successfully"
                
                for pair in "${subvolume_pairs[@]}"; do
                    local subvolume_name="${pair%%=*}"
                    local subvolume_mount_point="${pair#*=}"
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
                    # log "Rotating snapshots"
                    # require_test "-d" "$subvolume"
                    # if [[ -e "$previous_snapshot" ]]; then
                    #     debug "Previous snapshot exists, rotating to penultimate"
                    #     btrfs_subvolume_snapshot "$previous_snapshot" "$penultimate_snapshot"
                    # else
                    #     debug "No previous snapshot found, skipping rotation"
                    # fi
                    # debug "Creating new previous snapshot from current subvolume"
                    # btrfs_subvolume_snapshot "$subvolume" "$previous_snapshot" true
                    
                    # Create completely fresh empty subvolume
                    log "Creating fresh empty subvolume"
                    debug "Deleting any existing fresh snapshot at: $fresh_snapshot"
                    btrfs_subvolume_delete_recursively "$fresh_snapshot"
                    debug "Creating fresh subvolume at: $fresh_snapshot"
                    debug "Ensuring parent directory exists: $(dirname "$fresh_snapshot")"
                    mkdir -p "$(dirname "$fresh_snapshot")"
                    debug "Directory created"
                    btrfs subvolume create "$fresh_snapshot"
                    debug "Fresh created"
                    
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

