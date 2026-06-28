# homeModule: true
{ config, pkgs, lib, ... }:
let cfg = config.awww;
in {
  options.awww = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable awww wallpaper daemon.";
    };

    sessionTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      description = "Systemd session target to bind awww services to.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to the initial wallpaper image.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.awww ];

    systemd.user.services.awww-daemon = {
      Unit = {
        Description = "awww wallpaper daemon";
        PartOf = [ cfg.sessionTarget ];
        After = [ cfg.sessionTarget ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.awww}/bin/awww-daemon --format xrgb";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = { WantedBy = [ cfg.sessionTarget ]; };
    };

    systemd.user.services.awww-wallpaper = lib.mkIf (cfg.wallpaper != "") {
      Unit = {
        Description = "Set initial wallpaper with awww";
        After = [ "awww-daemon.service" ];
        PartOf = [ cfg.sessionTarget ];
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
        ExecStart = "${pkgs.awww}/bin/awww img ${cfg.wallpaper}";
        RemainAfterExit = true;
      };
      Install = { WantedBy = [ cfg.sessionTarget ]; };
    };
  };
}
