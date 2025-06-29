{ pkgs, config, lib, inputs, background, hostName, theme, ... }: {
  imports = [ ../waybar-hyprland.nix ];

  # Disable the general waybar module when using Hyprland
  programs.waybar.enable = lib.mkForce true;
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

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Monitor configuration - matches your desktop setup
      monitor = [
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
        border_size = 1;
        "col.active_border" = lib.mkForce "rgb(cba6f7)"; # Catppuccin mauve
        "col.inactive_border" = lib.mkForce "rgb(6c7086)"; # Catppuccin overlay0
        resize_on_border = false;
        allow_tearing = false;
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

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;

        touchpad = { natural_scroll = false; };

        sensitivity = 0;
      };

      # Environment variables
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "NIXOS_OZONE_WL,1"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "LIBVA_DRIVER_NAME,nvidia"
        "__GL_VRR_ALLOWED,1"
        "WLR_DRM_NO_ATOMIC,1"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
      ];

      # Autostart
      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "nm-applet"
        "blueman-applet"
        "udiskie --tray"
        "hypridle"
        "hyprpaper"
      ];

      # Key bindings
      bind = [
        # Window management
        "$mod, Q, killactive"
        "$mod, T, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, D, exec, $HOME/.config/rofi/scripts/launcher_t3"
        "$mod SHIFT, P, exec, $HOME/.config/rofi/scripts/powermenu_t1"
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

      # Workspace rules
      workspace = [
        "1, monitor:DP-6"
        "2, monitor:DP-4"
        "3, monitor:DP-6"
        "4, monitor:DP-6"
        "5, monitor:DP-6"
        "6, monitor:DP-6"
        "7, monitor:DP-6"
        "8, monitor:DP-6"
        "9, monitor:DP-6"
        "10, monitor:DP-6"
      ];

      # Window rules for Steam gaming
      windowrulev2 = [
        "idleinhibit focus, class:^(steam)$"
        "idleinhibit focus, class:^(steamwebhelper)$"
        "idleinhibit focus, class:^(steam_app_.*)$"
        "idleinhibit focus, title:^(Steam Big Picture Mode)$"
        "idleinhibit focus, class:^(gamescope)$"
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

      wallpaper =
        [ "DP-6,${background.wallpaper}" "DP-4,${background.wallpaper}" ];
    };
  };
}
