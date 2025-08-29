{ pkgs, config, lib, inputs, background, hostName, theme, ... }:
let
  # Theme color definitions
  themeColors = {
    catppuccin-mocha = {
      active_border = "rgb(cba6f7)"; # mauve
      inactive_border = "rgb(6c7086)"; # overlay0
      locked_active = "rgb(f9e2af)"; # yellow
      locked_inactive = "rgb(585b70)"; # surface2
      text = "rgb(cdd6f4)"; # text
      groupbar_active = "rgb(cba6f7)"; # mauve
      groupbar_inactive = "rgb(313244)"; # surface0
      groupbar_locked_active = "rgb(f9e2af)"; # yellow
      groupbar_locked_inactive = "rgb(585b70)"; # surface2
    };
    tokyo-night = {
      active_border = "rgb(7aa2f7)"; # blue
      inactive_border = "rgb(565f89)"; # comment
      locked_active = "rgb(e0af68)"; # yellow
      locked_inactive = "rgb(3b4261)"; # bg_highlight
      text = "rgb(c0caf5)"; # foreground
      groupbar_active = "rgb(7aa2f7)"; # blue
      groupbar_inactive = "rgb(24283b)"; # bg_dark
      groupbar_locked_active = "rgb(e0af68)"; # yellow
      groupbar_locked_inactive = "rgb(3b4261)"; # bg_highlight
    };
    everforest = {
      active_border = "rgb(a7c080)"; # green
      inactive_border = "rgb(7a8478)"; # grey1
      locked_active = "rgb(dbbc7f)"; # yellow
      locked_inactive = "rgb(4f5b58)"; # bg2
      text = "rgb(d3c6aa)"; # fg
      groupbar_active = "rgb(a7c080)"; # green
      groupbar_inactive = "rgb(2d353b)"; # bg0
      groupbar_locked_active = "rgb(dbbc7f)"; # yellow
      groupbar_locked_inactive = "rgb(4f5b58)"; # bg2
    };
  };

  colors = themeColors.${theme} or themeColors.catppuccin-mocha;
in {
  home.packages = with pkgs; [
    hyprpaper
    hypridle
    hyprlock
    swww
    grim
    slurp
    wl-clipboard
    light
    blueman
    networkmanagerapplet
    udiskie
    rofi-wayland
  ];

  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemdIntegration = true;
    systemd.variables = [ "--all" ];

    settings = {
      # Monitor configuration per host
      monitor = if hostName == "thinkpad" then
        [
          "eDP-1,1920x1080@60,0x0,1" # Built-in laptop display
        ]
      else [
        "DP-6,2560x1440@165,0x0,1" # Main monitor
        "DP-4,2560x1440@165,2560x0,1,transform,3" # Secondary monitor rotated 270°
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
        "col.active_border" = lib.mkForce colors.active_border;
        "col.inactive_border" = lib.mkForce colors.inactive_border;
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
        "col.border_active" = lib.mkForce colors.active_border;
        "col.border_inactive" = lib.mkForce colors.inactive_border;
        "col.border_locked_active" = lib.mkForce colors.locked_active;
        "col.border_locked_inactive" = lib.mkForce colors.locked_inactive;

        groupbar = {
          enabled = true;
          font_family = "JetBrainsMono Nerd Font";
          font_size = 12;
          gradients = false;
          height = 16;
          priority = 3;
          render_titles = true;
          scrolling = true;
          text_color = lib.mkForce colors.text;
          "col.active" = lib.mkForce colors.groupbar_active;
          "col.inactive" = lib.mkForce colors.groupbar_inactive;
          "col.locked_active" = lib.mkForce colors.groupbar_locked_active;
          "col.locked_inactive" = lib.mkForce colors.groupbar_locked_inactive;
        };
      };

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;

        touchpad = { natural_scroll = true; };

        sensitivity = 0;
      };

      # Environment variables
      env = [ "XCURSOR_SIZE,24" "HYPRCURSOR_SIZE,24" ];

      # Autostart
      exec-once = [
        "nm-applet"
        "blueman-applet"
        "udiskie --tray"
        "waybar -c ~/.config/waybar/config-hyprland.jsonc -s ~/.config/waybar/style.css"
      ];

      # Key bindings
      bind = [
        # Window management
        "$mod, Q, killactive"
        "$mod, T, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, D, exec, rofi -show drun -theme $HOME/.config/rofi/${theme}.rasi"
        "$mod SHIFT, P, exec, $HOME/.local/bin/powermenu powermenu-${theme}"
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
        "$mod SHIFT, W, exec, hyprctl dispatch dpms on"

        # Resize mode
        "$mod, R, submap, resize"
      ];

      # Resize submap
      submap = [
        "resize"
        "bind = , J, resizeactive, -10 0"
        "bind = , K, resizeactive, 0 -10"
        "bind = , L, resizeactive, 0 10"
        "bind = , SEMICOLON, resizeactive, 10 0"
        "bind = , LEFT, resizeactive, -10 0"
        "bind = , DOWN, resizeactive, 0 10"
        "bind = , UP, resizeactive, 0 -10"
        "bind = , RIGHT, resizeactive, 10 0"
        "bind = , RETURN, submap, reset"
        "bind = , ESCAPE, submap, reset"
        "bind = $mod, R, submap, reset"
        "submap = reset"
      ];

      # Function keys
      bindel = [
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +10%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -10%"
        ", XF86MonBrightnessUp, exec, light -A 5"
        ", XF86MonBrightnessDown, exec, light -U 5"
      ];

      # Special keys
      bindl = [
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SOURCE@ toggle"
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
        disable_loading_bar = true;
        grace = 300;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = lib.mkForce [{
        path = "${background.wallpaper}";
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

  # Hyprpaper configuration
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload = [ "${background.wallpaper}" ];

      wallpaper = if hostName == "thinkpad" then
        [ "eDP-1,${background.wallpaper}" ]
      else [
        "DP-6,${background.wallpaper}"
        "DP-4,${background.wallpaper}"
      ];
    };
  };
}
