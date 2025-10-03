{ config, pkgs, lib, ... }:
let cfg = config.snapshots;
in {
  options.snapshots.enable =
    lib.mkEnableOption "Enable btrfs filesystem snapshots";
  config = lib.mkIf cfg.enable {
    services.snapper = {
      snapshotInterval = "hourly";

      configs = {
        root = {
          SUBVOLUME = "/";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "24";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "3";
          TIMELINE_LIMIT_YEARLY = "0";
        };

        home = {
          SUBVOLUME = "/home";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "24";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "3";
          TIMELINE_LIMIT_YEARLY = "0";
        };
      };
    };

    system.activationScripts.snapperSubvolumes = ''
      if [ ! -d /home/.snapshots ]; then
        ${pkgs.btrfs-progs}/bin/btrfs subvolume create /home/.snapshots
        chmod 755 /home/.snapshots
        chown root:root /home/.snapshots
      fi
    '';
  };
}
