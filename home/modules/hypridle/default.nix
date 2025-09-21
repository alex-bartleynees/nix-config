{ pkgs, theme, lib, ... }: {
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
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800; # 30 minutes - suspend first
          on-timeout = "systemctl suspend";
        }
        {
          timeout = 5400; # 90 minutes total - hibernate if still asleep
          on-timeout = "systemctl hibernate";
        }
      ];
    };
  };

  # Hyprlock configuration
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
      };

      animation = "fade, 0";

      background = lib.mkForce [{
        path = "${theme.wallpaper}";
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
}
