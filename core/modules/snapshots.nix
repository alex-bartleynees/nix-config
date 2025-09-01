{ config, pkgs, lib, ... }:
let cfg = config.snapshots;
in {
  options.snapshots.enable =
    lib.mkEnableOption "Enable btrfs filesystem snapshots";
  config = lib.mkIf cfg.enable {
    services.snapper = {
      snapshotInterval = "daily";

      configs = {
        root = {
          SUBVOLUME = "/@";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "0";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "0";
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "0";
        };

        home = {
          SUBVOLUME = "/@home";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "0";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "0";
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "0";
        };
      };
    };
  };
}
