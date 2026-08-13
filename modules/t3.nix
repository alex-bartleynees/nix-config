{
  nixosConfig = { config, lib, pkgs, users, ... }:
    let cfg = config.services.t3;
    in {
      options.services.t3 = {
        enable = lib.mkEnableOption "t3 server (system service)";
        user = lib.mkOption {
          type = lib.types.str;
          default = (builtins.head users).username;
          description = "User to run the t3 server as.";
        };
        host = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0";
          description = "Address t3 serve binds to.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.services.t3 = {
          description = "t3 server";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          path = with pkgs; [ git gh openssh ];
          environment = { SHELL = "${pkgs.bash}/bin/bash"; };
          serviceConfig = {
            ExecStart = "${pkgs.t3code}/bin/t3 serve --host ${cfg.host}";
            User = cfg.user;
            Restart = "on-failure";
          };
        };
      };
    };

  homeConfig = { config, lib, pkgs, ... }:
    let cfg = config.services.t3;
    in {
      options.services.t3 = {
        enable = lib.mkEnableOption "t3 server (systemd --user service)";
        host = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0";
          description = "Address t3 serve binds to.";
        };
        enableLinger = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.user.services.t3 = {
          Unit = {
            Description = "t3 server";
            After = [ "network.target" ];
          };
          Service = {
            ExecStart = "${pkgs.t3code}/bin/t3 serve --host ${cfg.host}";
            Environment = [
              "PATH=${
                lib.makeBinPath (with pkgs; [ git gh openssh ])
              }:/usr/bin:/bin"
              "SHELL=${pkgs.bash}/bin/bash"
            ];
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };

        home.activation.t3EnableLinger = lib.mkIf cfg.enableLinger
          (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /usr/bin/sudo /usr/bin/loginctl enable-linger "$USER" || true
          '');
      };
    };
}
