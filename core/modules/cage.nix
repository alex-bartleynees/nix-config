{ config, lib, pkgs, users, ... }:
let cfg = config.cage;
in {
  options.cage = {
    enable = lib.mkEnableOption "Cage Wayland kiosk configuration";

    application = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.moonlight-qt}/bin/moonlight";
      description = "Application to run in kiosk mode";
    };

    cageArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-s" ];
      description = "Arguments to pass to cage";
    };

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = if users != [ ] then (builtins.head users).username else null;
      description = "User for auto-login (null disables auto-login)";
    };

    enableAutoLogin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic login for single-user systems";
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = lib.mkMerge [
        {
          default_session = {
            command = "${pkgs.cage}/bin/cage ${
                lib.concatStringsSep " " cfg.cageArgs
              } -- ${cfg.application}";
          };
        }
        (lib.mkIf (cfg.enableAutoLogin && cfg.user != null
          && builtins.length users == 1) {
            initial_session = {
              command = "${pkgs.cage}/bin/cage ${
                  lib.concatStringsSep " " cfg.cageArgs
                } -- ${cfg.application}";
              user = cfg.user;
            };
          })
      ];
    };
  };
}
