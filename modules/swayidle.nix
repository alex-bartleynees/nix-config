{
  nixosConfig = { ... }: {
    security.pam.services.swaylock = { text = "auth include login"; };
  };

  homeConfig = { config, pkgs, lib, ... }:
    let
      cfg = config.swayidle;
      lockScript = "${config.home.homeDirectory}/.local/bin/lock.sh";
    in {
      options.swayidle = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable swayidle and swaylock configuration.";
        };

        lockTimeout = lib.mkOption {
          type = lib.types.int;
          default = 300;
          description = "Timeout in seconds before locking the screen.";
        };

        displayTimeout = lib.mkOption {
          type = lib.types.int;
          default = 600;
          description = "Timeout in seconds before turning off displays.";
        };

        suspendTimeout = lib.mkOption {
          type = lib.types.int;
          default = 1800;
          description = "Timeout in seconds before suspending the system.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Path to wallpaper image for swaylock background.";
        };

        displayOffCommand = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Command to turn off displays when idle.";
        };

        displayOnCommand = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Command to turn displays back on when resuming.";
        };

        preLockScript = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            Shell commands prepended to the lock script before set -e.
            Useful for compositor-specific env setup (e.g. exporting SWAYSOCK).
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = with pkgs; [ swayidle swaylock ];

        services.swayidle = {
          enable = true;
          timeouts = [{
            timeout = cfg.lockTimeout;
            command = lockScript;
          }] ++ lib.optional (cfg.displayOffCommand != "") ({
            timeout = cfg.displayTimeout;
            command = cfg.displayOffCommand;
          } // lib.optionalAttrs (cfg.displayOnCommand != "") {
            resumeCommand = cfg.displayOnCommand;
          }) ++ [{
            timeout = cfg.suspendTimeout;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }];
          events = {
            before-sleep = lockScript;
          } // lib.optionalAttrs (cfg.displayOnCommand != "") {
            after-resume = cfg.displayOnCommand;
          };
        };

        home.file.".local/bin/lock.sh" = {
          text = ''
            #!${pkgs.bash}/bin/bash
            ${cfg.preLockScript}
            set -e
            ${lib.optionalString (cfg.displayOnCommand != "")
            cfg.displayOnCommand}
            ${pkgs.swaylock}/bin/swaylock -f${
              lib.optionalString (cfg.wallpaper != "") " -i ${cfg.wallpaper}"
            }
          '';
          executable = true;
        };
      };
    };
}
