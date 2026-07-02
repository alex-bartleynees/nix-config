{
  homeConfig = { config, pkgs, lib, ... }:
    let cfg = config.udiskie;
    in {
      options.udiskie = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable udiskie automounter.";
        };

        sessionTarget = lib.mkOption {
          type = lib.types.str;
          default = "graphical-session.target";
          description = "Systemd session target to bind the udiskie service to.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.udiskie ];

        systemd.user.services.udiskie = {
          Unit = {
            Description = "Udiskie automounter";
            PartOf = [ cfg.sessionTarget ];
            After = [ cfg.sessionTarget ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.udiskie}/bin/udiskie --tray";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
          Install = { WantedBy = [ cfg.sessionTarget ]; };
        };
      };
    };
}
