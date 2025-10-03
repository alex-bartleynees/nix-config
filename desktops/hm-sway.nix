{ pkgs, config, lib, hostName, theme, ... }:
let
  colors = theme.themeColors;
  background = theme.wallpaper;
in {
  imports = [ ./common/hm-linux-desktop.nix ];
  home.packages = with pkgs; [
    swaybg
    swayidle
    swaylock
    sway-audio-idle-inhibit
    autotiling-rs
  ];

  # Sway configuration using wayland.windowManager.sway
  wayland.windowManager.sway = {
    enable = true;
    package = null;
    systemd.enable = true;
    wrapperFeatures.gtk = true;

    config = {
      # Variables
      modifier = "Mod1"; # Alt key
      terminal = "ghostty";

      # Window settings
      window = {
        border = 1;
        titlebar = false;
      };

      gaps = {
        inner = 10;
        smartGaps = true;
      };

      # Fonts
      fonts = { names = [ "JetBrainsMono Nerd Font" ]; };

      # Colors based on theme
      colors = {
        focused = {
          border = lib.mkForce colors.active_border;
          background = lib.mkForce colors.active_border;
          text = lib.mkForce colors.text;
          indicator = lib.mkForce colors.active_border;
          childBorder = lib.mkForce colors.active_border;
        };
        focusedInactive = {
          border = lib.mkForce colors.inactive_border;
          background = lib.mkForce colors.groupbar_inactive;
          text = lib.mkForce colors.text;
          indicator = lib.mkForce colors.inactive_border;
          childBorder = lib.mkForce colors.inactive_border;
        };
        unfocused = {
          border = lib.mkForce colors.inactive_border;
          background = lib.mkForce colors.groupbar_inactive;
          text = lib.mkForce colors.text;
          indicator = lib.mkForce colors.inactive_border;
          childBorder = lib.mkForce colors.inactive_border;
        };
        urgent = {
          border = lib.mkForce colors.locked_active;
          background = lib.mkForce colors.groupbar_inactive;
          text = lib.mkForce colors.locked_active;
          indicator = lib.mkForce colors.inactive_border;
          childBorder = lib.mkForce colors.locked_active;
        };
      };

      # Key bindings
      keybindings =
        let modifier = config.wayland.windowManager.sway.config.modifier;
        in lib.mkOptionDefault {
          # Application shortcuts
          "${modifier}+t" =
            "exec ${config.wayland.windowManager.sway.config.terminal}";
          "${modifier}+b" = "exec brave";
          "${modifier}+c" = "exec code";
          "${modifier}+d" =
            "exec rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi";
          "${modifier}+Shift+p" =
            "exec $HOME/.local/bin/powermenu powermenu-${theme.name}";
          "${modifier}+Shift+t" =
            "exec $HOME/.local/bin/themeselector powermenu-${theme.name}";
          "${modifier}+Shift+w" =
            "exec $HOME/.local/bin/wallpaper ${theme.name}";
          "${modifier}+i" = "exec $HOME/.local/bin/keybindings ${theme.name}";

          # Screenshot
          "${modifier}+p" = ''exec grim -g "$(slurp -d)" - | wl-copy'';

          # Lock screen
          "Control+${modifier}+l" = "exec ~/.config/sway/lock.sh";

          # Focus movement (Vi keys)
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";

          # Move windows (Vi keys)
          "${modifier}+Shift+h" = "move left";
          "${modifier}+Shift+j" = "move down";
          "${modifier}+Shift+k" = "move up";
          "${modifier}+Shift+l" = "move right";

          # Layout switching
          "${modifier}+s" = "layout stacking";
          "${modifier}+w" = "layout tabbed";
          "${modifier}+e" = "layout toggle split";

          # Floating
          "${modifier}+Shift+space" = "floating toggle";

          # Fullscreen
          "${modifier}+f" = "fullscreen toggle";

          # Focus parent
          "${modifier}+a" = "focus parent";

          # Kill window
          "${modifier}+q" = "kill";

          # Reload config
          "${modifier}+Shift+c" = "reload";

          # Restart sway
          "${modifier}+Shift+r" = "restart";

          # Exit sway
          "${modifier}+Shift+e" = "exec swaymsg exit";

          # Scratchpad
          "${modifier}+Control+Shift+minus" = "move scratchpad";
          "${modifier}+Control+minus" = "scratchpad show";

          # Resize mode
          "${modifier}+r" = "mode resize";

          # Audio controls
          "XF86AudioRaiseVolume" =
            "exec pactl set-sink-volume @DEFAULT_SINK@ +10%";
          "XF86AudioLowerVolume" =
            "exec pactl set-sink-volume @DEFAULT_SINK@ -10%";
          "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioMicMute" =
            "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

          # Brightness controls
          "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

          # Wake displays (host-specific) - using Ctrl+Shift+w to avoid conflict
          "Control+${modifier}+w" = if hostName == "thinkpad" then
            ''exec swaymsg "output eDP-1 dpms on"''
          else
            ''exec swaymsg "output DP-6 dpms on; output DP-4 dpms on"'';
        };

      # Modes
      modes = {
        resize = {
          "h" = "resize shrink width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize grow width 10 px or 10 ppt";
          "Left" = "resize shrink width 10 px or 10 ppt";
          "Down" = "resize grow height 10 px or 10 ppt";
          "Up" = "resize shrink height 10 px or 10 ppt";
          "Right" = "resize grow width 10 px or 10 ppt";
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };

      # Window rules for Steam gaming
      window.commands = [
        {
          criteria = { class = "^steam_app_streaming_client$"; };
          command = "inhibit_idle focus";
        }
        {
          criteria = { class = "^steamwebhelper$"; };
          command = "inhibit_idle focus";
        }
        {
          criteria = { class = "^steam$"; };
          command = "inhibit_idle focus";
        }
        {
          criteria = { title = "^Steam Big Picture Mode$"; };
          command = "inhibit_idle focus";
        }
        {
          criteria = { class = "^steam_app.*$"; };
          command = "inhibit_idle focus";
        }
        {
          criteria = { class = "^Steam$"; };
          command = "inhibit_idle focus";
        }
      ];

      # Input configuration
      input = {
        "*" = { xkb_layout = "us"; };
        "type:touchpad" = { natural_scroll = "enabled"; };
      };

      # Output configuration per host
      output = if hostName == "thinkpad" then {
        "eDP-1" = {
          mode = "1920x1080@60Hz";
          position = "0,0";
          background = "${background} fill";
        };
      } else {
        "DP-6" = {
          mode = "2560x1440@164.958Hz";
          position = "0,0";
          background = "${background} fill";
          adaptive_sync = "on";
        };
        "DP-4" = {
          mode = "2560x1440@144Hz";
          position = "2560,0";
          transform = "90";
          background = "${background} fill";
          adaptive_sync = "on";
        };
      };

      # Workspace assignments per host
      workspaceOutputAssign = if hostName == "thinkpad" then [
        {
          workspace = "1";
          output = "eDP-1";
        }
        {
          workspace = "2";
          output = "eDP-1";
        }
        {
          workspace = "3";
          output = "eDP-1";
        }
        {
          workspace = "4";
          output = "eDP-1";
        }
        {
          workspace = "5";
          output = "eDP-1";
        }
        {
          workspace = "6";
          output = "eDP-1";
        }
        {
          workspace = "7";
          output = "eDP-1";
        }
        {
          workspace = "8";
          output = "eDP-1";
        }
        {
          workspace = "9";
          output = "eDP-1";
        }
        {
          workspace = "10";
          output = "eDP-1";
        }
      ] else [
        {
          workspace = "1";
          output = "DP-6";
        }
        {
          workspace = "2";
          output = "DP-6";
        }
        {
          workspace = "3";
          output = "DP-6";
        }
        {
          workspace = "4";
          output = "DP-6";
        }
        {
          workspace = "5";
          output = "DP-6";
        }
        {
          workspace = "6";
          output = "DP-4";
        }
        {
          workspace = "7";
          output = "DP-4";
        }
        {
          workspace = "8";
          output = "DP-4";
        }
        {
          workspace = "9";
          output = "DP-4";
        }
        {
          workspace = "10";
          output = "DP-4";
        }
      ];

      # Startup applications
      startup = [
        {
          command =
            "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
        }
        { command = "nm-applet"; }
        { command = "blueman-applet"; }
        { command = "udiskie --tray"; }
        { command = "sway-audio-idle-inhibit"; }
        { command = "swww-daemon --format xrgb"; }
        { command = "sleep 1 && swww img ${background}"; }
        { command = "autotiling-rs"; }
        {
          command = "uwsm finalize SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME";
        }
      ];

      # Disable default sway bar
      bars = [ ];
    };
  };

  # Swayidle configuration
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "loginctl lock-session";
      }
      {
        timeout = 600;
        command = if hostName == "thinkpad" then
          ''swaymsg "output eDP-1 dpms off"''
        else
          ''swaymsg "output DP-6 dpms off"; swaymsg "output DP-4 dpms off"'';
        resumeCommand = if hostName == "thinkpad" then
          ''swaymsg "output eDP-1 dpms on"''
        else
          ''swaymsg "output DP-6 dpms on"; swaymsg "output DP-4 dpms on"'';
      }
      {
        timeout = 1800; # 30 minutes - suspend first
        command = "systemctl suspend";
      }
      {
        timeout = 5400; # 90 minutes total - hibernate if still asleep
        command = "systemctl hibernate";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "loginctl lock-session";
      }
      {
        event = "after-resume";
        command = if hostName == "thinkpad" then
          ''swaymsg "output eDP-1 dpms on"''
        else
          ''swaymsg "output DP-6 dpms on"; swaymsg "output DP-4 dpms on"'';
      }
    ];
  };

  # Lock script
  home.file.".config/sway/lock.sh" = {
    text = ''
      #!/bin/sh
      export SWAYSOCK=/run/user/1000/sway-ipc.$(id -u).$(pgrep -x sway).sock
      export WAYLAND_DISPLAY=wayland-1
      set -e

      # Turn off screen blanking
      swaymsg "output * dpms on"

      # Run swaylock
      swaylock -i ${background}

      # Re-enable DPMS settings after unlocking
      swaymsg "output * dpms on"
    '';
    executable = true;
  };

  # Waybar systemd service
  systemd.user.services.waybar-sway = {
    Unit = {
      Description = "Highly customizable Wayland bar for Sway";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      PartOf = [ "sway-session.target" ];
      After = [ "sway-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config.json -s %h/.config/waybar/style.css";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install = { WantedBy = [ "sway-session.target" ]; };
  };

  # XDG configuration for UWSM
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
}
