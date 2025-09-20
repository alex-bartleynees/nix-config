{ config, lib, pkgs, ... }:
let
  # Build the Rust immutability binary
  immutability-rs = pkgs.rustPlatform.buildRustPackage {
    pname = "immutability";
    version = "0.1.0";
    src = ./immutability-rs;
    cargoLock.lockFile = ./immutability-rs/Cargo.lock;

    nativeBuildInputs = with pkgs; [ btrfs-progs ];
    buildInputs = with pkgs; [ btrfs-progs ];

    meta = {
      description = "Fast BTRFS impermanence manager";
      license = lib.licenses.mit;
    };
  };

  # Find BTRFS filesystem by label
  device = "/dev/disk/by-label/nixos";

  # Use standard crypted device name since we're using nixos label
  luksDeviceName = "crypted";
  deviceDependency = "dev-mapper-${luksDeviceName}.device";
  snapshotsSubvolumeName = "@snapshots";

  pathsToKeep = lib.strings.concatStringsSep " " config.impermanence.persistPaths;

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

  subvolumeNameMountPointPairs = getResetSubvolumes;

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
          immutability = "${immutability-rs}/bin/immutability";
          btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
          cp = "${pkgs.coreutils}/bin/cp";
          chown = "${pkgs.coreutils}/bin/chown";
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
          script = ''
            # Set environment variables for Rust logging
            export RUST_LOG=info
            export RUST_BACKTRACE=1

            # Call the Rust binary with the provided arguments
            exec immutability "${device}" "${snapshotsSubvolumeName}" "${subvolumeNameMountPointPairs}" "${pathsToKeep}"
          '';
        };
      };
    };
  };
}
