{ config, lib, pkgs, ... }:
let
  # Find BTRFS filesystem by label 
  device = "/dev/disk/by-label/nixos";

  getLuksDeviceName = diskoDevices:
    let
      findLuksInPartitions = partitions:
        lib.findFirst (partition:
          partition.content.type or null == "luks"
          && partition.content.content.type or null == "btrfs"
          && (lib.elem "-L" (partition.content.content.extraArgs or [ ])
            && lib.elem "nixos" (partition.content.content.extraArgs or [ ])))
        null (lib.attrValues partitions);

      findInDisks = lib.findFirst (disk:
        let result = findLuksInPartitions (disk.content.partitions or { });
        in result != null) null (lib.attrValues (diskoDevices.disk or { }));
    in if findInDisks != null then
      let
        partition =
          findLuksInPartitions (findInDisks.content.partitions or { });
      in partition.content.name
    else
      "crypted";

  luksDeviceName = getLuksDeviceName config.disko.devices;
  deviceDependency = "dev-mapper-${luksDeviceName}.device";
  snapshotsSubvolumeName = "@snapshots";

  pathsToKeep =
    ''"${lib.strings.concatStringsSep " " config.impermanence.persistPaths}"'';

  # Extract subvolumes that should be reset from disko configuration
  getBtrfsSubvolumes = diskoDevices:
    let
      findBtrfsInPartitions = partitions:
        lib.findFirst (partition:
          partition.content.type or null == "luks"
          && partition.content.content.type or null == "btrfs"
          && (lib.elem "-L" (partition.content.content.extraArgs or [ ])
            && lib.elem "nixos" (partition.content.content.extraArgs or [ ])))
        null (lib.attrValues partitions);

      findInDisks = lib.findFirst (disk:
        let result = findBtrfsInPartitions (disk.content.partitions or { });
        in result != null) null (lib.attrValues (diskoDevices.disk or { }));
    in if findInDisks != null then
      let
        partition =
          findBtrfsInPartitions (findInDisks.content.partitions or { });
      in partition.content.content.subvolumes or { }
    else
      { };

  subvolumes = getBtrfsSubvolumes config.disko.devices;

  getResetSubvolumes = let
    # Function to check if a subvolume should never be reset
    isProtectedSubvolume = name: 
      name == "@nix" || 
      name == "@snapshots" || 
      lib.hasInfix ".snapshots" name; # Protect any subvolume containing .snapshots
      
    resetSubvols = lib.filterAttrs (name: subvol:
      # If resetSubvolumes is empty, reset all except protected subvolumes
      # Otherwise only reset specified subvolumes (but still protect critical ones)
      if config.impermanence.resetSubvolumes == [ ] then
        !isProtectedSubvolume name
      else
        lib.elem name config.impermanence.resetSubvolumes && !isProtectedSubvolume name
    ) subvolumes;
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

  };

  config = lib.mkIf (config.impermanence.enable && subvolumes != { }) {
    # Mark reset subvolumes as needed for boot
    fileSystems = lib.mkMerge (let
      # Function to check if a subvolume should never be reset
      isProtectedSubvolume = name: 
        name == "@nix" || 
        name == "@snapshots" || 
        lib.hasInfix ".snapshots" name; # Protect any subvolume containing .snapshots
        
      resetSubvols = lib.filterAttrs (name: subvol:
        # If resetSubvolumes is empty, reset all except protected subvolumes
        # Otherwise only reset specified subvolumes (but still protect critical ones)
        if config.impermanence.resetSubvolumes == [ ] then
          !isProtectedSubvolume name
        else
          lib.elem name config.impermanence.resetSubvolumes && !isProtectedSubvolume name
      ) subvolumes;
    in lib.mapAttrsToList
    (name: subvol: { "${subvol.mountpoint}".neededForBoot = lib.mkForce true; })
    resetSubvols);

    boot.nixStoreMountOpts = [ "ro" ]; # Mount Nix store read-only
    boot.tmp.useTmpfs = true;

    boot.initrd = {
      supportedFilesystems = [ "btrfs" ];
      systemd = {
        extraBin = {
          python = "${pkgs.python3}/bin/python3";
          # Note: btrfs tools are usually available in initrd by default
        };
        contents."/immutability.py".text = ''
          #!/usr/bin/env python3
          import os
          import sys
          import subprocess
          import tempfile
          import shutil
          from pathlib import Path
          from typing import List, Dict, Set

          class Logger:
              def __init__(self):
                  self.depth = 0
              
              def log(self, *args):
                  indent = "  " * self.depth
                  message = " ".join(str(arg) for arg in args)
                  print(f"{indent}{message}")
              
              def warning(self, *args):
                  self.log("WRN", *args)
                  sys.stderr.flush()
              
              def error(self, *args):
                  self.log("ERR", *args)
                  sys.stderr.flush()
              
              def trace(self, cmd: List[str], check=True):
                  self.depth += 1
                  self.log(" ".join(cmd))
                  try:
                      result = subprocess.run(cmd, capture_output=True, text=True, check=check)
                      if result.stdout.strip():
                          for line in result.stdout.strip().split('\n'):
                              self.log(line)
                      if result.stderr.strip():
                          for line in result.stderr.strip().split('\n'):
                              self.warning(line)
                      self.depth -= 1
                      return result
                  except subprocess.CalledProcessError as e:
                      self.warning(f"Command failed with status {e.returncode}")
                      if e.stdout:
                          for line in e.stdout.strip().split('\n'):
                              self.log(line)
                      if e.stderr:
                          for line in e.stderr.strip().split('\n'):
                              self.error(line)
                      self.depth -= 1
                      if check:
                          raise
                      return e

          logger = Logger()

          def abort(message: str):
              logger.error(message)
              logger.error("Unmounting and quitting")
              cleanup()
              sys.exit(1)

          def cleanup():
              """Cleanup function to ensure proper unmounting"""
              try:
                  if os.path.ismount("/mnt"):
                      logger.trace(["umount", "-R", "/mnt"], check=False)
                      shutil.rmtree("/mnt", ignore_errors=True)
              except Exception as e:
                  logger.warning(f"Cleanup failed: {e}")

          def require_test(condition: str, path: str):
              """Test file conditions"""
              if condition == "-d":
                  if not os.path.isdir(path):
                      abort(f"Required directory does not exist: {path}")
              elif condition == "-b":
                  if not os.path.exists(path):
                      abort(f"Required block device does not exist: {path}")

          def btrfs_sync(path: str):
              logger.trace(["btrfs", "filesystem", "sync", path])

          def btrfs_subvolume_delete(path: str):
              if os.path.exists(path):
                  logger.trace(["btrfs", "subvolume", "delete", path, "--commit-after"])
                  btrfs_sync(os.path.dirname(path))

          def btrfs_subvolume_delete_recursively(path: str):
              if not os.path.exists(path):
                  return
              
              result = logger.trace(["btrfs", "subvolume", "list", "-o", path], check=False)
              if result.returncode == 0 and result.stdout:
                  lines = result.stdout.strip().split('\n')
                  for line in lines:
                      if line.strip():
                          parts = line.split()
                          if len(parts) >= 9:
                              subvol_path = " ".join(parts[8:])
                              full_path = os.path.join(os.path.dirname(path), subvol_path)
                              btrfs_subvolume_delete_recursively(full_path)
              
              btrfs_subvolume_delete(path)

          def btrfs_subvolume_snapshot(source: str, target: str, readonly=False):
              require_test("-d", source)
              btrfs_subvolume_delete_recursively(target)
              cmd = ["btrfs", "subvolume", "snapshot"]
              if readonly:
                  cmd.append("-r")
              cmd.extend([source, target])
              logger.trace(cmd)
              btrfs_sync(source)
              btrfs_sync(target)

          def btrfs_subvolume_rw(path: str):
              logger.trace(["btrfs", "property", "set", "-ts", path, "ro", "false"])

          def extract_persistent_files(subvolume_mount_point: str, paths_to_keep: List[str], 
                                     source_subvolume: str, temp_dir: str) -> str:
              """
              Extract persistent files from source subvolume into a temporary subvolume
              Returns the path to the temporary subvolume containing only persistent files
              """
              persistent_subvol = os.path.join(temp_dir, "persistent_files")
              
              # Create a minimal subvolume with just the persistent files
              logger.trace(["btrfs", "subvolume", "create", persistent_subvol])
              
              # Copy only the persistent files/directories
              for path_to_keep in paths_to_keep:
                  if path_to_keep.startswith(subvolume_mount_point):
                      rel_path = path_to_keep[len(subvolume_mount_point):].lstrip('/')
                      source_path = os.path.join(source_subvolume, rel_path)
                      target_path = os.path.join(persistent_subvol, rel_path)
                      
                      if os.path.exists(source_path):
                          # Create parent directories
                          os.makedirs(os.path.dirname(target_path), exist_ok=True)
                          
                          if os.path.isdir(source_path):
                              # For directories, use cp -a to preserve everything
                              logger.trace(["cp", "-a", source_path, target_path])
                          else:
                              # For files, copy with attributes
                              logger.trace(["cp", "-a", source_path, target_path])
                      else:
                          logger.warning(f"Persistent path not found: {source_path}")
              
              return persistent_subvol

          def apply_persistent_files_via_send_receive(persistent_subvol: str, target_subvolume: str):
              """
              Apply persistent files to target subvolume using btrfs send/receive
              """
              # First, create a readonly snapshot of the persistent files
              persistent_snapshot = f"{persistent_subvol}_snapshot"
              btrfs_subvolume_snapshot(persistent_subvol, persistent_snapshot, readonly=True)
              
              try:
                  # Use btrfs send to stream the persistent data
                  with tempfile.NamedTemporaryFile() as stream_file:
                      # Generate send stream
                      logger.log(f"Generating send stream from {persistent_snapshot}")
                      with open(stream_file.name, 'wb') as f:
                          send_proc = subprocess.Popen(
                              ["btrfs", "send", persistent_snapshot],
                              stdout=f,
                              stderr=subprocess.PIPE,
                              text=False
                          )
                          _, send_stderr = send_proc.communicate()
                          
                          if send_proc.returncode != 0:
                              logger.error(f"btrfs send failed: {send_stderr.decode()}")
                              raise subprocess.CalledProcessError(send_proc.returncode, "btrfs send")
                      
                      # Apply the stream to target subvolume
                      logger.log(f"Applying persistent files to {target_subvolume}")
                      with open(stream_file.name, 'rb') as f:
                          receive_proc = subprocess.Popen(
                              ["btrfs", "receive", target_subvolume],
                              stdin=f,
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE,
                              text=True
                          )
                          receive_stdout, receive_stderr = receive_proc.communicate()
                          
                          if receive_proc.returncode != 0:
                              logger.error(f"btrfs receive failed: {receive_stderr}")
                              # Fall back to direct file copying
                              logger.warning("Falling back to direct file copy")
                              logger.trace(["cp", "-a", f"{persistent_subvol}/.", f"{target_subvolume}/"])
                          else:
                              logger.log("Successfully applied persistent files via send/receive")
                              if receive_stdout:
                                  logger.log(receive_stdout)
                              
                              # The receive creates a new subvolume, we need to merge it
                              received_subvol = os.path.join(target_subvolume, os.path.basename(persistent_snapshot))
                              if os.path.exists(received_subvol):
                                  logger.trace(["cp", "-a", f"{received_subvol}/.", f"{target_subvolume}/"])
                                  btrfs_subvolume_delete(received_subvol)
              
              finally:
                  # Clean up the readonly snapshot
                  btrfs_subvolume_delete(persistent_snapshot)

          def mount_subvolumes(disk: str, mount_point: str, snapshots_subvolume: str, subvolume_names: List[str]):
              require_test("-b", disk)
              os.makedirs(mount_point, exist_ok=True)
              
              logger.trace(["mount", "-t", "btrfs", "-o", "subvolid=5,user_subvol_rm_allowed", disk, mount_point])
              
              for subvolume_name in subvolume_names + [snapshots_subvolume]:
                  subvol_mount = os.path.join(mount_point, subvolume_name)
                  os.makedirs(subvol_mount, exist_ok=True)
                  logger.trace(["mount", "-t", "btrfs", "-o", f"subvol={subvolume_name},user_subvol_rm_allowed", disk, subvol_mount])

          def unmount_subvolumes(mount_point: str):
              logger.trace(["umount", "-R", mount_point], check=False)
              shutil.rmtree(mount_point, ignore_errors=True)

          def main():
              if len(sys.argv) != 5:
                  abort("Usage: script <disk> <snapshots_subvolume> <subvol_pairs> <paths_to_keep>")
              
              disk = sys.argv[1]
              snapshots_subvolume_name = sys.argv[2]
              subvolume_pairs_str = sys.argv[3]
              paths_to_keep_str = sys.argv[4]
              
              subvolume_pairs = subvolume_pairs_str.split()
              paths_to_keep = sorted(paths_to_keep_str.split())
              subvolume_names = [pair.split('=')[0] for pair in subvolume_pairs]
              
              mount_point = "/mnt"
              
              logger.log(f"Starting btrfs send/receive impermanence reset for: {subvolume_names}")
              logger.log(f"Preserving paths: {paths_to_keep}")
              
              try:
                  mount_subvolumes(disk, mount_point, snapshots_subvolume_name, subvolume_names)
                  
                  for pair in subvolume_pairs:
                      subvolume_name, subvolume_mount_point = pair.split('=', 1)
                      logger.log(f"Processing subvolume: {subvolume_name}")
                      
                      subvolume = os.path.join(mount_point, subvolume_name)
                      snapshots_dir = os.path.join(mount_point, snapshots_subvolume_name, subvolume_name)
                      
                      previous_snapshot = os.path.join(snapshots_dir, "PREVIOUS")
                      penultimate_snapshot = os.path.join(snapshots_dir, "PENULTIMATE")
                      fresh_snapshot = os.path.join(snapshots_dir, "FRESH")
                      
                      os.makedirs(snapshots_dir, exist_ok=True)
                      
                      # Create temporary directory for persistent file extraction
                      with tempfile.TemporaryDirectory(dir=mount_point) as temp_dir:
                          logger.log("Extracting persistent files from current state")
                          persistent_subvol = extract_persistent_files(
                              subvolume_mount_point, paths_to_keep, subvolume, temp_dir
                          )
                          
                          # Rotate snapshots (keep history for debugging)
                          logger.log("Rotating snapshots")
                          if os.path.exists(previous_snapshot):
                              btrfs_subvolume_snapshot(previous_snapshot, penultimate_snapshot)
                          btrfs_subvolume_snapshot(subvolume, previous_snapshot, readonly=True)
                          
                          # Create completely fresh empty subvolume
                          logger.log("Creating fresh empty subvolume")
                          btrfs_subvolume_delete_recursively(fresh_snapshot)
                          logger.trace(["btrfs", "subvolume", "create", fresh_snapshot])
                          
                          # Apply persistent files to the fresh subvolume
                          logger.log("Applying persistent files to fresh subvolume")
                          apply_persistent_files_via_send_receive(persistent_subvol, fresh_snapshot)
                          
                          # Replace current subvolume with fresh one
                          logger.log("Replacing subvolume with fresh snapshot")
                          btrfs_subvolume_delete_recursively(subvolume)
                          btrfs_subvolume_snapshot(fresh_snapshot, subvolume)
                          
                          # Clean up the fresh snapshot (we don't need to keep it)
                          btrfs_subvolume_delete(fresh_snapshot)
                      
                      logger.log(f"Completed processing {subvolume_name}")
                  
              except Exception as e:
                  abort(f"Fatal error: {e}")
              finally:
                  unmount_subvolumes(mount_point)
              
              logger.log("Btrfs send/receive impermanence reset completed successfully")

          if __name__ == "__main__":
              main()
        '';
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
            /immutability.py ${device} ${snapshotsSubvolumeName} ${subvolumeNameMountPointPairs} ${pathsToKeep}

            # Add a marker file to indicate system was reset
            touch /sysroot/tmp/.nixos-needs-rebuild
          '';
        };
      };
    };

    # Critical: Auto-rebuild NixOS configuration early in boot process
    systemd.services.nixos-auto-rebuild = {
      description = "Auto-rebuild NixOS configuration after impermanence reset";
      wantedBy = [ "multi-user.target" ];
      # Run after basic filesystem setup but before user services
      after = [ "local-fs.target" "systemd-remount-fs.service" ];
      before = [
        "display-manager.service"
        "getty@tty1.service"
        "systemd-user-sessions.service" # Blocks user logins until complete
      ];
      unitConfig = {
        DefaultDependencies = false;
        ConditionPathExists = "/tmp/.nixos-needs-rebuild";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        StandardError = "journal";
        # Ensure we have a clean environment
        Environment = [
          "HOME=/root"
          "USER=root"
          "PATH=${lib.makeBinPath [ pkgs.nixos-rebuild pkgs.git pkgs.nix ]}"
        ];
        ExecStart = pkgs.writeScript "auto-rebuild" ''
          #!/bin/bash
          set -euo pipefail

          echo "=== NixOS Auto-Rebuild Starting ==="
          echo "System was reset, rebuilding declarative configuration..."

          # Check for host identifier to determine which flake target to build
          if [ -f /etc/hostname-for-rebuild ]; then
            HOST=$(cat /etc/hostname-for-rebuild)
            echo "Building for host: $HOST"
            
            # Use the home flake configuration
            cd /home/alexbn/.config/nix-config
            if nixos-rebuild switch --flake ".#$HOST" --install-bootloader; then
              echo "=== NixOS rebuild completed successfully ==="
              rm -f /tmp/.nixos-needs-rebuild
            else
              echo "=== NixOS rebuild failed! ==="
              echo "Manual intervention may be required."
              exit 1
            fi
          else
            echo "ERROR: /etc/hostname-for-rebuild not found!"
            echo "Please create this file with your host name (e.g., 'echo thinkpad | sudo tee /etc/hostname-for-rebuild')"
            exit 1
          fi
        '';
        # If rebuild fails, don't block the boot process entirely
        # but log the failure clearly
        ExecStartPost = pkgs.writeScript "rebuild-cleanup" ''
          #!/bin/bash
          if [ -f /tmp/.nixos-needs-rebuild ]; then
            echo "WARNING: NixOS rebuild failed, system may not be properly configured!"
            echo "Run 'sudo nixos-rebuild switch' manually when possible."
            # Create a prominent warning file
            echo "NixOS rebuild failed on $(date)" > /etc/REBUILD_FAILED_WARNING
          fi
        '';
      };
    };

    # Ensure the rebuild service blocks user sessions
    systemd.services."systemd-user-sessions".after =
      [ "nixos-auto-rebuild.service" ];

    # Alternative: If you want to be even more aggressive, prevent all logins until rebuild completes
    systemd.services."getty@".after = [ "nixos-auto-rebuild.service" ];
    systemd.services."serial-getty@".after = [ "nixos-auto-rebuild.service" ];

    # Prevent SSH logins until rebuild is complete (if using SSH)
    systemd.services."sshd".after = [ "nixos-auto-rebuild.service" ];

    # Optional: Show rebuild progress on console
    systemd.services.rebuild-progress = {
      description = "Show rebuild progress on console";
      wantedBy = [ "multi-user.target" ];
      after = [ "nixos-auto-rebuild.service" ];
      unitConfig.ConditionPathExists = "!/tmp/.nixos-needs-rebuild";
      serviceConfig = {
        Type = "oneshot";
        StandardOutput = "tty";
        TTYPath = "/dev/tty1";
        ExecStart = pkgs.writeScript "show-progress" ''
          #!/bin/bash
          echo
          echo "✓ NixOS configuration rebuilt successfully"
          echo "✓ System ready for use"
          echo
        '';
      };
    };

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

        case "''${1:-}" in
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
