{
  nixosConfig = { pkgs, lib, ... }: {
    imports = [ ./common/wayland.nix ];

    programs.niri = {
      enable = true;
      useNautilus = false;
    };

    environment.systemPackages = with pkgs; [
      xwayland-satellite
      uwsm
    ];

    programs.uwsm = {
      enable = true;
      waylandCompositors.niri = {
        binPath = "/run/current-system/sw/bin/niri";
        prettyName = "Niri";
        comment = "Niri compositor with UWSM";
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals =
        [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ];
      config = {
        niri = {
          default = lib.mkForce [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = lib.mkForce [ "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        };
      };
      xdgOpenUsePortal = true;
    };

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
    };

    displayManager = {
      enable = true;
      autoLogin = {
        enable = true;
        command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.niri}/bin/niri";
      };
    };

    system.nixos.tags = [ "niri" ];
  };

  homeConfig = { pkgs, config, lib, osConfig, ... }:
    let
      theme = osConfig.myConfig.theme;
      monitors = osConfig.myConfig.monitors;
      colors = theme.themeColors;
      background = theme.wallpaper;
      sh = cmd: [ "sh" "-c" cmd ];
    in {
      imports = [ ./common/linux-desktop.nix ];

      # Enable hypridle with theme wallpaper
      hypridle = {
        enable = true;
        wallpaper = background;
        displayOffCommand =
          "${pkgs.niri}/bin/niri msg action power-off-monitors";
        displayOnCommand =
          "${pkgs.niri}/bin/niri msg action power-on-monitors";
      };

      waybar.sessionTarget = "wayland-session@niri.target";

      udiskie = {
        enable = true;
        sessionTarget = "wayland-session@niri.target";
      };

      awww = {
        enable = true;
        sessionTarget = "wayland-session@niri.target";
        wallpaper = background;
      };

      vicinae = {
        enable = true;
        sessionTarget = "wayland-session@niri.target";
      };

      wayland.windowManager.niri = {
        enable = true;
        package = pkgs.niri;
        systemd.enable = false;
        xwaylandSatellitePackage = null;
        portalPackage = null;

        settings = {
          # Input configuration
          input = {
            keyboard.xkb = {
              layout = "us";
              # Use Alt as modifier key (matching hyprland/river configs)
              options = "altwin:swap_alt_win";
            };
            mouse.accel-speed = 1.0;
            touchpad = {
              tap = { };
              dwt = { };
              natural-scroll = { };
              click-method = "clickfinger";
            };
            # Focus follows mouse
            focus-follows-mouse = { };
          };

          prefer-no-csd = { };

          # Layout configuration
          layout = {
            gaps = 10;
            border = {
              width = 3;
              active-color = "#${builtins.substring 1 6 colors.active_border}";
              inactive-color =
                "#${builtins.substring 1 6 colors.inactive_border}";
            };

            always-center-single-column = { };

            focus-ring.off = { };

            preset-column-widths._children = [
              { proportion = 1.0 / 3.0; }
              { proportion = 1.0 / 2.0; }
              { proportion = 2.0 / 3.0; }
              { proportion = 1.0; }
            ];

            default-column-width.proportion = 1.0;

            # Transparent background so wallpaper stays stationary in backdrop
            background-color = "transparent";

            # Tab indicator configuration
            tab-indicator = { };
          };

          hotkey-overlay.skip-at-startup = { };

          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

          # Environment variables
          environment = {
            XCURSOR_SIZE = "24";
            NIXOS_OZONE_WL = "1";
            NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";
          };

          # Key bindings
          binds = {
            # Application shortcuts
            "Mod+T".spawn = [ "ghostty" ];
            "Mod+B".spawn = [ "brave" ];
            "Mod+C".spawn = [ "code" ];
            "Mod+D".spawn = sh
              "rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi";
            "Mod+Space".spawn = sh "vicinae toggle";
            "Mod+Shift+P".spawn =
              sh "$HOME/.local/bin/powermenu powermenu-${theme.name}";
            "Mod+Shift+T".spawn =
              sh "$HOME/.local/bin/themeselector powermenu-${theme.name}";
            "Mod+Shift+W".spawn =
              sh "$HOME/.local/bin/wallpaper ${theme.name}";
            "Mod+I".spawn = sh "$HOME/.local/bin/keybindings ${theme.name}";

            # Lock screen
            "Mod+Ctrl+L".spawn = [ "hyprlock" ];

            # Screenshot
            "Mod+P".spawn = sh ''grim -g "$(slurp -d)" - | wl-copy'';
            "Print".screenshot-screen = { };
            "Mod+Print".screenshot-window = { };

            # Volume control
            "XF86AudioRaiseVolume".spawn =
              sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+";
            "XF86AudioLowerVolume".spawn =
              sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-";
            "XF86AudioMute".spawn =
              sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "XF86AudioMicMute".spawn =
              sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

            # Brightness control
            "XF86MonBrightnessUp".spawn = sh "brightnessctl set +5%";
            "XF86MonBrightnessDown".spawn = sh "brightnessctl set 5%-";

            # Window management
            "Mod+Q".close-window = { };
            "Mod+F".fullscreen-window = { };
            "Mod+Shift+Space".toggle-window-floating = { };
            "Mod+W".toggle-column-tabbed-display = { };

            # Focus movement (Vi keys)
            "Mod+H".focus-column-left = { };
            "Mod+J".focus-window-down = { };
            "Mod+K".focus-window-up = { };
            "Mod+L".focus-column-right = { };

            # Focus movement (Arrow keys)
            "Mod+Left".focus-column-left = { };
            "Mod+Down".focus-window-down = { };
            "Mod+Up".focus-window-up = { };
            "Mod+Right".focus-column-right = { };

            # Move windows (Vi keys)
            "Mod+Shift+H".move-column-left = { };
            "Mod+Shift+J".move-window-down = { };
            "Mod+Shift+K".move-window-up = { };
            "Mod+Shift+L".move-column-right = { };

            # Move windows (Arrow keys)
            "Mod+Shift+Left".move-column-left = { };
            "Mod+Shift+Down".move-window-down = { };
            "Mod+Shift+Up".move-window-up = { };
            "Mod+Shift+Right".move-column-right = { };

            # Workspace switching
            "Mod+1".focus-workspace = 1;
            "Mod+2".focus-workspace = 2;
            "Mod+3".focus-workspace = 3;
            "Mod+4".focus-workspace = 4;
            "Mod+5".focus-workspace = 5;
            "Mod+6".focus-workspace = 6;
            "Mod+7".focus-workspace = 7;
            "Mod+8".focus-workspace = 8;
            "Mod+9".focus-workspace = 9;
            "Mod+0".focus-workspace = 10;

            # Move to workspace
            "Mod+Shift+1".move-window-to-workspace = 1;
            "Mod+Shift+2".move-window-to-workspace = 2;
            "Mod+Shift+3".move-window-to-workspace = 3;
            "Mod+Shift+4".move-window-to-workspace = 4;
            "Mod+Shift+5".move-window-to-workspace = 5;
            "Mod+Shift+6".move-window-to-workspace = 6;
            "Mod+Shift+7".move-window-to-workspace = 7;
            "Mod+Shift+8".move-window-to-workspace = 8;
            "Mod+Shift+9".move-window-to-workspace = 9;
            "Mod+Shift+0".move-window-to-workspace = 10;

            # Column management
            "Mod+Comma".consume-window-into-column = { };
            "Mod+Period".expel-window-from-column = { };

            # Column width
            "Mod+R".switch-preset-column-width = { };
            "Mod+Shift+F".maximize-column = { };
            "Mod+Minus".set-column-width = "-10%";
            "Mod+Plus".set-column-width = "+10%";
            "Mod+Shift+Minus".set-window-height = "-10%";
            "Mod+Shift+Plus".set-window-height = "+10%";

            # Tab/group navigation
            "Mod+Tab".focus-window-down-or-column-right = { };
            "Mod+Shift+Tab".focus-window-up-or-column-left = { };

            # Overview
            "Mod+O".toggle-overview = { };

            # System
            "Mod+Shift+E".quit._props.skip-confirmation = true;
            "Mod+Shift+C".spawn = sh "niri msg action load-config-file";

            # Mouse wheel scrolling for switching windows/workspaces
            "Mod+WheelScrollDown".focus-column-right = { };
            "Mod+WheelScrollUp".focus-column-left = { };
            "Mod+Shift+WheelScrollDown".focus-workspace-down = { };
            "Mod+Shift+WheelScrollUp".focus-workspace-up = { };
          };

          # Repeated top-level KDL nodes (outputs, layer-rule, window-rule, spawn-at-startup)
          _children = (map (m: {
            output = {
              _args = [ (if m.description != "" then m.description else m.name) ];
              mode =
                "${toString m.width}x${toString m.height}@${toString m.refresh}";
              position._props = {
                x = m.x;
                y = m.y;
              };
              scale = m.scale;
            } // lib.optionalAttrs m.vrr {
              variable-refresh-rate = { };
            } // lib.optionalAttrs (m.transform != 0) {
              transform = toString (360 - m.transform);
            };
          }) monitors) ++ [
            # Layer rules for wallpaper backdrop
            {
              layer-rule = {
                match._props.namespace = "^awww-daemon$";
                place-within-backdrop = true;
              };
            }

            # Window rules
            {
              window-rule = {
                draw-border-with-background = false;
                geometry-corner-radius = 5.0;
                clip-to-geometry = true;
              };
            }
            {
              window-rule = {
                match._props.app-id = "^steam_app_.*$";
                open-fullscreen = true;
              };
            }

            # Startup commands
            {
              spawn-at-startup = [
                "dbus-update-activation-environment"
                "--systemd"
                "WAYLAND_DISPLAY"
                "XDG_CURRENT_DESKTOP"
              ];
            }
            {
              spawn-at-startup = [
                "systemctl"
                "--user"
                "import-environment"
                "WAYLAND_DISPLAY"
                "XDG_CURRENT_DESKTOP"
              ];
            }
            { spawn-at-startup = [ "nm-applet" ]; }
            { spawn-at-startup = [ "blueman-applet" ]; }
            {
              spawn-at-startup = [
                "uwsm"
                "finalize"
                "SWAYSOCK"
                "I3SOCK"
                "XCURSOR_SIZE"
                "XCURSOR_THEME"
                "NIRI_SOCKET"
              ];
            }
          ];
        };
      };

      # XDG configuration for Niri/UWSM compatibility
      xdg.configFile."uwsm/env".source =
        "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
    };
}
