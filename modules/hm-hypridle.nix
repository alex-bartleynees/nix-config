{ config, pkgs, lib, ... }:
let cfg = config.hypridle;
in {
  options.hypridle = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Hypridle and Hyprlock configuration.";
    };

    lockTimeout = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Timeout in seconds before locking the session.";
    };

    displayTimeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
      description = "Timeout in seconds before turning off the display.";
    };

    suspendTimeout = lib.mkOption {
      type = lib.types.int;
      default = 1800;
      description = "Timeout in seconds before suspending the system.";
    };

    hibernateTimeout = lib.mkOption {
      type = lib.types.int;
      default = 5400;
      description = "Timeout in seconds before hibernating the system.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to wallpaper for lock screen background.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ hypridle hyprlock ];

    # Hypridle configuration
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = cfg.lockTimeout;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = cfg.displayTimeout;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = cfg.suspendTimeout;
            on-timeout = "systemctl suspend";
          }
          {
            timeout = cfg.hibernateTimeout;
            on-timeout = "systemctl hibernate";
          }
        ];
      };
    };

    # Hyprlock configuration
    programs.hyprlock = {
      enable = true;
      settings = {
        general = { hide_cursor = true; };

        animation = "fade, 0";

        background = lib.mkForce [{
          path = lib.mkIf (cfg.wallpaper != "") cfg.wallpaper;
          blur_passes = 3;
          blur_size = 8;
        }];

        input-field = lib.mkForce [{
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = "Password...";
          shadow_passes = 2;
        }];
      };
    };
  };
}
