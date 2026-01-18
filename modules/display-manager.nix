{ config, lib, pkgs, users, ... }:
let cfg = config.displayManager;
in {
  options.displayManager = {
    # Enable display manager setup
    enable = lib.mkEnableOption "display manager setup";
    autoLogin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically log in to the display manager";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = (builtins.head users).username;
        description = "The user to log in automatically";
      };
      command = lib.mkOption {
        type = lib.types.str;
        default =
          "${pkgs.uwsm}/bin/uwsm start ${pkgs.hyprland}/bin/start-hyprland";
        description = "The command to run for the initial session";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.greetd = { enable = true; };
      security.pam.services.greetd.enable = true;
      programs.regreet = {
        enable = true;
        cageArgs = [ "-s" "-m" "last" ];
      };
    })

    (lib.mkIf (cfg.autoLogin.enable && (builtins.length users == 1)) {
      services.greetd.settings = {
        initial_session = {
          command = cfg.autoLogin.command;
          user = cfg.autoLogin.user;
        };
      };
    })
  ];

}
