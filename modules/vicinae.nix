# homeModule: true
{ config, pkgs, lib, ... }:
let cfg = config.vicinae;
in {
  options.vicinae = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Vicinae application launcher.";
    };

    sessionTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      description = "Systemd user target to bind the vicinae server service to.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.vicinae ];

    systemd.user.services.vicinae = {
      Unit = {
        Description = "Vicinae application launcher server";
        Documentation = "https://github.com/tim-harding/vicinae";
        PartOf = [ cfg.sessionTarget ];
        After = [ cfg.sessionTarget ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.vicinae}/bin/vicinae server";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = { WantedBy = [ cfg.sessionTarget ]; };
    };
  };
}
