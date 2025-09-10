{ pkgs, config, lib, inputs, hostName, theme, ... }:
let
  colors = theme.themeColors;
  background = theme.wallpaper;

  # Function to convert hex colors to rgb format for Hyprland
  hexToRgb = hex: "rgb(${builtins.substring 1 6 hex})";
in {
  home.packages = with pkgs; [
    hyprpaper
    swww
    grim
    slurp
    wl-clipboard
    brightnessctl
    blueman
    networkmanagerapplet
    udiskie
    rofi-wayland
  ];

  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
  stylix.targets.hyprland.enable = false;

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = true;
    systemd.variables = [ "--all" ];

    settings = {
      # Monitor configuration per host
      monitor = if hostName == "thinkpad" then
        [
          "eDP-1,1920x1080@60,0x0,1" # Built-in laptop display
        ]
      else [
        "DP-6,2560x1440@165,0x0,1" # Main monitor
        "DP-4,2560x1440@144,2560x0,1,transform,3" # Secondary monitor rotated 270°
      ];

      # Variables
      "$mod" = "ALT";
      "$terminal" = "ghostty";
      "$browser" = "brave";
      "$lock" = "hyprlock";

      # General settings
      general = {
        gaps_in = 10;
        gaps_out = 10;
        border_size = 3;
        "col.active_border" = lib.mkForce (hexToRgb colors.active_border);
        "col.inactive_border" = lib.mkForce (hexToRgb colors.inactive_border);
        resize_on_border = false;
        allow_tearing = true;
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 5;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        blur = { enabled = false; };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 4, myBezier"
          "windowsOut, 1, 4, default, popin 80%"
          "border, 1, 6, default"
          "borderangle, 1, 5, default"
          "fade, 1, 4, default"
          "workspaces, 1, 3, default"
        ];
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Group styling
      group = {
        "col.border_active" = lib.mkForce (hexToRgb colors.active_border);
        "col.border_inactive" = lib.mkForce (hexToRgb colors.inactive_border);
        "col.border_locked_active" =
          lib.mkForce (hexToRgb colors.locked_active);
        "col.border_locked_inactive" =
          lib.mkForce (hexToRgb colors.locked_inactive);

        groupbar = {
          enabled = true;
          font_family = "JetBrainsMono Nerd Font";
          font_size = 12;
          gradients = false;
          height = 16;
          priority = 3;
          render_titles = true;
          scrolling = true;
          text_color = lib.mkForce (hexToRgb colors.text);
          "col.active" = lib.mkForce (hexToRgb colors.groupbar_active);
          "col.inactive" = lib.mkForce (hexToRgb colors.groupbar_inactive);
          "col.locked_active" =
            lib.mkForce (hexToRgb colors.groupbar_locked_active);
          "col.locked_inactive" =
            lib.mkForce (hexToRgb colors.groupbar_locked_inactive);
        };
      };

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;

        touchpad = { natural_scroll = true; };

        sensitivity = 0;
      };

      # Gestures configuration
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      # Environment variables
      env = [ "XCURSOR_SIZE,24" "HYPRCURSOR_SIZE,24" ];

      # Autostart
      exec = [
        "systemctl --user restart hyprland-session.target"
        "systemctl --user restart waybar"
      ];
      exec-once = [
        "nm-applet"
        "blueman-applet"
        "udiskie --tray"
        "swww-daemon --format xrgb"
      ];

      # Key bindings
      bind = [
        # Window management
        "$mod, Q, killactive"
        "$mod, T, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, C, exec, code"
        "$mod, D, exec, rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi"
        "$mod SHIFT, P, exec, $HOME/.local/bin/powermenu powermenu-${theme.name}"
        "$mod SHIFT, T, exec, $HOME/.local/bin/themeselector powermenu-${theme.name}"
        "$mod SHIFT, W, exec, $HOME/.local/bin/wallpaper ${theme.name}"
        "$mod, I, exec, $HOME/.local/bin/keybindings ${theme.name}"
        "$mod, F, fullscreen"
        "$mod SHIFT, SPACE, togglefloating"
        #"$mod, A, focusparent"
        ''$mod, P, exec, grim -g "$(slurp -d)" - | wl-copy''

        # Focus movement (Vi keys)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Focus movement (Arrow keys)
        "$mod, LEFT, movefocus, l"
        "$mod, RIGHT, movefocus, r"
        "$mod, UP, movefocus, u"
        "$mod, DOWN, movefocus, d"

        # Move windows (Vi keys)
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Move windows (Arrow keys)
        "$mod SHIFT, LEFT, movewindow, l"
        "$mod SHIFT, RIGHT, movewindow, r"
        "$mod SHIFT, UP, movewindow, u"
        "$mod SHIFT, DOWN, movewindow, d"

        # Workspace switching
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Layout switching
        "$mod, S, exec, hyprctl keyword general:layout master"
        "$mod, W, togglegroup"
        "$mod, E, exec, hyprctl keyword general:layout dwindle"

        # Togglegroup navigation
        "$mod, TAB, changegroupactive, f"
        "$mod SHIFT, TAB, changegroupactive, b"

        # Configuration
        "$mod SHIFT, C, exec, hyprctl reload"
        "$mod SHIFT, E, exit"

        # Scratchpad
        "$mod CTRL SHIFT, MINUS, movetoworkspace, special"
        "$mod CTRL, MINUS, togglespecialworkspace"

        # Lock and display control
        "CTRL $mod, L, exec, $lock"
        "$mod CTRL, W, exec, hyprctl dispatch dpms on"
        ''$mod CTRL, M, exec, hyprctl keyword monitor "DP-4,disable"''
        ''
          $mod CTRL SHIFT, M, exec, hyprctl keyword monitor "DP-4,2560x1440@144,2560x0,1,transform,3"''

        # Resize mode
        "$mod, R, submap, resize"
      ];

      # Resize submap
      # submap = [
      #   "resize"
      #   "bind = , J, resizeactive, -10 0"
      #   "bind = , K, resizeactive, 0 -10"
      #   "bind = , L, resizeactive, 0 10"
      #   "bind = , SEMICOLON, resizeactive, 10 0"
      #   "bind = , LEFT, resizeactive, -10 0"
      #   "bind = , DOWN, resizeactive, 0 10"
      #   "bind = , UP, resizeactive, 0 -10"
      #   "bind = , RIGHT, resizeactive, 10 0"
      #   "bind = , RETURN, submap, reset"
      #   "bind = , ESCAPE, submap, reset"
      #   "bind = $mod, R, submap, reset"
      #   "submap = reset"
      # ];

      # Function keys
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      # Special keys
      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      # Mouse bindings
      bindm = [ "$mod, mouse:272, movewindow" "$mod, mouse:273, resizewindow" ];

      # Workspace rules per host
      workspace = if hostName == "thinkpad" then [
        "1, monitor:eDP-1"
        "2, monitor:eDP-1"
        "3, monitor:eDP-1"
        "4, monitor:eDP-1"
        "5, monitor:eDP-1"
        "6, monitor:eDP-1"
        "7, monitor:eDP-1"
        "8, monitor:eDP-1"
        "9, monitor:eDP-1"
        "10, monitor:eDP-1"
      ] else [
        "1, monitor:DP-6"
        "2, monitor:DP-6"
        "3, monitor:DP-6"
        "4, monitor:DP-6"
        "5, monitor:DP-6"
        "6, monitor:DP-4"
        "7, monitor:DP-4"
        "8, monitor:DP-4"
        "9, monitor:DP-4"
        "10, monitor:DP-4"
      ];

      # Window rules for Steam gaming
      windowrulev2 = [
        "idleinhibit focus, class:^(steam)$"
        "idleinhibit focus, class:^(steamwebhelper)$"
        "idleinhibit focus, class:^(steam_app_.*)$"
        "idleinhibit focus, title:^(Steam Big Picture Mode)$"
        "idleinhibit focus, class:^(gamescope)$"

        # Steam main window
        #"float, class:^(steam)$"
        #"monitor DP-6, class:^(steam)$"

        # Steam Big Picture Mode
        #"float, class:^(steam)$, title:^(Steam Big Picture Mode)$"
        #"monitor DP-6, class:^(steam)$, title:^(Steam Big Picture Mode)$"

        #Steam games - force proper display settings
        "fullscreen, class:^(steam_app_.*)$"
        "monitor DP-6, class:^(steam_app_.*)$"
        "workspace 1, class:^(steam_app_.*)$"
        "immediate, class:^(steam_app_.*)$"
      ];

      # Misc settings
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        enable_swallow = true;
        swallow_regex = "^(ghostty|kitty|alacritty)$";
      };

      # Cursor settings for NVIDIA
      cursor = { no_hardware_cursors = true; };

      # XWayland settings
      xwayland = { force_zero_scaling = true; };
    };
  };

  # Waybar systemd service
  systemd.user.services.waybar = {
    Unit = {
      Description =
        "Highly customizable Wayland bar for Sway and Wlroots based compositors";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config.json -s %h/.config/waybar/style.css";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
  };

  # Hyprpaper configuration - commented out in favor of swww
  # services.hyprpaper = {
  #   enable = true;
  #   settings = {
  #     ipc = "on";
  #     splash = false;
  #     splash_offset = 2.0;

  #     preload = [ "${background}" ];

  #     wallpaper = if hostName == "thinkpad" then
  #       [ "eDP-1,${background}" ]
  #     else [
  #       "DP-6,${background}"
  #       "DP-4,${background}"
  #     ];
  #   };
  # };
}
