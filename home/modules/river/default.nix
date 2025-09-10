{ pkgs, config, lib, inputs, hostName, theme, ... }:
let
  colors = theme.themeColors;
  background = theme.wallpaper;
in {
  imports = [ ../hypridle ];
  home.packages = with pkgs; [
    river-classic
    river-bsp-layout
    swww
    grim
    slurp
    wl-clipboard
    brightnessctl
    blueman
    networkmanagerapplet
    udiskie
    rofi-wayland
    hyprlock
    waybar
    wlr-randr
  ];

  wayland.windowManager.river = {
    enable = true;
    package = pkgs.river-classic;
    xwayland.enable = true;

    settings = {
      # Set keyboard layout
      keyboard-layout = "us";

      # Set repeat rate and delay
      set-repeat = "50 300";

      # Set border colors
      border-color-focused =
        lib.mkForce "0x${builtins.substring 1 6 colors.active_border}";
      border-color-unfocused =
        lib.mkForce "0x${builtins.substring 1 6 colors.inactive_border}";
      border-color-urgent =
        lib.mkForce "0x${builtins.substring 1 6 colors.locked_active}";
      border-width = 2;

      # Set the default layout generator
      default-layout = "bsp-layout";

      # Key mappings - using Alt as modifier (consistent with Sway/Hyprland)
      map = {
        normal = {
          # Application shortcuts
          "Alt T" = "spawn ghostty";
          "Alt B" = "spawn brave";
          "Alt C" = "spawn code";
          "Alt D" =
            "spawn 'rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi'";
          "Alt+Shift P" =
            "spawn '$HOME/.local/bin/powermenu powermenu-${theme.name}'";
          "Alt+Shift T" =
            "spawn '$HOME/.local/bin/themeselector powermenu-${theme.name}'";
          "Alt+Shift W" = "spawn '$HOME/.local/bin/wallpaper ${theme.name}'";
          "Alt I" = "spawn '$HOME/.local/bin/keybindings ${theme.name}'";

          # Screenshot
          "Alt P" = "spawn 'sh -c \"grim -g \\\"$(slurp -d)\\\" - | wl-copy\"'";

          # Lock screen
          "Control+Alt L" = "spawn 'hyprlock'";

          # Window management
          "Alt Q" = "close";
          "Alt+Shift E" = "exit";

          # Focus movement (Vi keys)
          "Alt J" = "focus-view next";
          "Alt K" = "focus-view previous";
          "Alt H" = "send-layout-cmd rivertile 'main-ratio -0.05'";
          "Alt L" = "send-layout-cmd rivertile 'main-ratio +0.05'";

          # Move windows
          "Alt+Shift J" = "swap next";
          "Alt+Shift K" = "swap previous";
          "Alt+Shift H" = "send-layout-cmd rivertile 'main-count +1'";
          "Alt+Shift L" = "send-layout-cmd rivertile 'main-count -1'";

          # Focus outputs
          "Alt Period" = "focus-output next";
          "Alt Comma" = "focus-output previous";
          "Alt+Shift Period" = "send-to-output next";
          "Alt+Shift Comma" = "send-to-output previous";

          # Zoom focused view to top
          "Alt Return" = "zoom";

          # Toggle states
          "Alt Space" = "toggle-float";
          "Alt F" = "toggle-fullscreen";

          # Layout orientation
          "Alt Up" = "send-layout-cmd rivertile 'main-location top'";
          "Alt Right" = "send-layout-cmd rivertile 'main-location right'";
          "Alt Down" = "send-layout-cmd rivertile 'main-location bottom'";
          "Alt Left" = "send-layout-cmd rivertile 'main-location left'";

          # Passthrough mode
          "Alt F11" = "enter-mode passthrough";

          # Workspaces (tags in River)
          "Alt 1" = "set-focused-tags 1";
          "Alt 2" = "set-focused-tags 2";
          "Alt 3" = "set-focused-tags 4";
          "Alt 4" = "set-focused-tags 8";
          "Alt 5" = "set-focused-tags 16";
          "Alt 6" = "set-focused-tags 32";
          "Alt 7" = "set-focused-tags 64";
          "Alt 8" = "set-focused-tags 128";
          "Alt 9" = "set-focused-tags 256";
          "Alt 0" = "set-focused-tags 4294967295";

          # Move to workspaces
          "Alt+Shift 1" = "set-view-tags 1";
          "Alt+Shift 2" = "set-view-tags 2";
          "Alt+Shift 3" = "set-view-tags 4";
          "Alt+Shift 4" = "set-view-tags 8";
          "Alt+Shift 5" = "set-view-tags 16";
          "Alt+Shift 6" = "set-view-tags 32";
          "Alt+Shift 7" = "set-view-tags 64";
          "Alt+Shift 8" = "set-view-tags 128";
          "Alt+Shift 9" = "set-view-tags 256";
          "Alt+Shift 0" = "set-view-tags 4294967295";

          # Toggle focus of tags
          "Alt+Control 1" = "toggle-focused-tags 1";
          "Alt+Control 2" = "toggle-focused-tags 2";
          "Alt+Control 3" = "toggle-focused-tags 4";
          "Alt+Control 4" = "toggle-focused-tags 8";
          "Alt+Control 5" = "toggle-focused-tags 16";
          "Alt+Control 6" = "toggle-focused-tags 32";
          "Alt+Control 7" = "toggle-focused-tags 64";
          "Alt+Control 8" = "toggle-focused-tags 128";
          "Alt+Control 9" = "toggle-focused-tags 256";

          # Toggle view tags
          "Alt+Shift+Control 1" = "toggle-view-tags 1";
          "Alt+Shift+Control 2" = "toggle-view-tags 2";
          "Alt+Shift+Control 3" = "toggle-view-tags 4";
          "Alt+Shift+Control 4" = "toggle-view-tags 8";
          "Alt+Shift+Control 5" = "toggle-view-tags 16";
          "Alt+Shift+Control 6" = "toggle-view-tags 32";
          "Alt+Shift+Control 7" = "toggle-view-tags 64";
          "Alt+Shift+Control 8" = "toggle-view-tags 128";
          "Alt+Shift+Control 9" = "toggle-view-tags 256";

          # Media keys in normal mode
          "None XF86AudioRaiseVolume" =
            "spawn 'pactl set-sink-volume @DEFAULT_SINK@ +10%'";
          "None XF86AudioLowerVolume" =
            "spawn 'pactl set-sink-volume @DEFAULT_SINK@ -10%'";
          "None XF86AudioMute" =
            "spawn 'pactl set-sink-mute @DEFAULT_SINK@ toggle'";
          "None XF86AudioMicMute" =
            "spawn 'pactl set-source-mute @DEFAULT_SOURCE@ toggle'";
          "None XF86MonBrightnessUp" = "spawn 'brightnessctl set +5%'";
          "None XF86MonBrightnessDown" = "spawn 'brightnessctl set 5%-'";
        };

        # Media keys for both normal and locked modes
        locked = {
          "None XF86AudioRaiseVolume" =
            "spawn 'pactl set-sink-volume @DEFAULT_SINK@ +10%'";
          "None XF86AudioLowerVolume" =
            "spawn 'pactl set-sink-volume @DEFAULT_SINK@ -10%'";
          "None XF86AudioMute" =
            "spawn 'pactl set-sink-mute @DEFAULT_SINK@ toggle'";
          "None XF86AudioMicMute" =
            "spawn 'pactl set-source-mute @DEFAULT_SOURCE@ toggle'";
          "None XF86MonBrightnessUp" = "spawn 'brightnessctl set +5%'";
          "None XF86MonBrightnessDown" = "spawn 'brightnessctl set 5%-'";
        };

        # Passthrough mode
        passthrough = { "Alt F11" = "enter-mode normal"; };
      };

      # Mouse bindings
      map-pointer = {
        normal = {
          "Alt BTN_LEFT" = "move-view";
          "Alt BTN_RIGHT" = "resize-view";
          "Alt BTN_MIDDLE" = "toggle-float";
        };
      };
    };

    extraConfig = ''
      # Host-specific output configuration
      ${if hostName == "thinkpad" then ''
        riverctl output eDP-1 mode 1920x1080@60
        riverctl output eDP-1 position 0,0
      '' else ''
        wlr-randr --output DP-6 --pos 0,0 --output DP-4 --transform 270 --pos 2560,0 &
      ''}

      # Server Side Decorations (SSD) rules for border visibility
      riverctl rule-add -app-id "brave-browser" ssd
      riverctl rule-add -app-id "code" ssd
      riverctl rule-add -app-id "firefox" ssd
      riverctl rule-add -app-id "thunar" ssd
      riverctl rule-add -app-id "discord" ssd
      riverctl rule-add -app-id "steam" ssd
      riverctl rule-add -app-id "chromium-browser" ssd
      riverctl rule-add -app-id "com.mitchellh.ghostty" ssd

      # Startup applications
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
      nm-applet &
      blueman-applet &
      udiskie --tray &
      swww-daemon --format xrgb &

      # Set wallpaper with swww after daemon starts
      sleep 1 && swww img "${background}" &

      # UWSM finalize for proper session management
      uwsm finalize SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME &

      # Start rivertile layout generator
      #rivertile -view-padding 6 -outer-padding 6 &
      river-bsp-layout --inner-gap 5 --outer-gap 10 --split-perc 0.5 &

      # Ensure borders are visible by setting focus ring
      riverctl focus-follows-cursor normal
    '';

    extraSessionVariables = {
      XCURSOR_SIZE = "24";
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "river";
      XDG_SESSION_DESKTOP = "river";
    };
  };

  # XDG configuration for River/UWSM compatibility
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  # Waybar systemd service for River
  systemd.user.services.waybar-river = {
    Unit = {
      Description = "Highly customizable Wayland bar for River";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      PartOf = [ "river-session.target" ];
      After = [ "river-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config.json -s %h/.config/waybar/style.css";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install = { WantedBy = [ "river-session.target" ]; };
  };
}

