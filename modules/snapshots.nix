{ config, pkgs, lib, ... }:
let
  cfg = config.snapshots;
  mkLimitOption = default:
    lib.mkOption {
      type = lib.types.str;
      inherit default;
    };
in {
  options.snapshots = {
    enable = lib.mkEnableOption "Enable btrfs filesystem snapshots";

    limits = {
      hourly = mkLimitOption "24";
      daily = mkLimitOption "7";
      weekly = mkLimitOption "4";
      monthly = mkLimitOption "3";
      yearly = mkLimitOption "0";
    };
  };
  config = lib.mkIf cfg.enable {
    services.snapper = {
      snapshotInterval = "hourly";

      configs = {
        root = {
          SUBVOLUME = "/";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = cfg.limits.hourly;
          TIMELINE_LIMIT_DAILY = cfg.limits.daily;
          TIMELINE_LIMIT_WEEKLY = cfg.limits.weekly;
          TIMELINE_LIMIT_MONTHLY = cfg.limits.monthly;
          TIMELINE_LIMIT_YEARLY = cfg.limits.yearly;
        };

        home = {
          SUBVOLUME = "/home";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = cfg.limits.hourly;
          TIMELINE_LIMIT_DAILY = cfg.limits.daily;
          TIMELINE_LIMIT_WEEKLY = cfg.limits.weekly;
          TIMELINE_LIMIT_MONTHLY = cfg.limits.monthly;
          TIMELINE_LIMIT_YEARLY = cfg.limits.yearly;
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
