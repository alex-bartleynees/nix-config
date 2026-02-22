{
  nixosConfig = { pkgs, inputs, ... }: {
    imports = [ ./common/wayland.nix inputs.niri.nixosModules.niri ];

    programs.niri.enable = true;
    programs.niri.package = pkgs.niri-unstable;
    nixpkgs.overlays = [ inputs.niri.overlays.niri ];

    environment.systemPackages = with pkgs; [
      xwayland-satellite-unstable
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
        [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
      config = {
        niri = {
          default = [ "hyprland" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        };
      };
      xdgOpenUsePortal = true;
    };

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
    };

    security.pam.services.hyprlock = { };

    displayManager = {
      enable = true;
      autoLogin = {
        enable = true;
        command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.niri-unstable}/bin/niri";
      };
    };

    system.nixos.tags = [ "niri" ];
  };

  homeConfig = { pkgs, config, lib, hostName, theme, inputs, ... }:
    let
      colors = theme.themeColors;
      background = theme.wallpaper;
    in {
      imports = [ ./common/linux-desktop.nix ];

      # Enable hypridle with theme wallpaper
      hypridle = {
        enable = true;
        wallpaper = background;
      };

      programs.niri.package = pkgs.niri-unstable;

      stylix.targets.niri.enable = false;

      programs.niri.settings = {
        # Input configuration
        input.keyboard.xkb.layout = "us";
        input.mouse.accel-speed = 1.0;
        input.touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };

        prefer-no-csd = true;

        # Use Alt as modifier key (matching hyprland/river configs)
        input.keyboard.xkb.options = "altwin:swap_alt_win";

        # Focus follows mouse
        input.focus-follows-mouse.enable = true;

        # Layout configuration
        layout = {
          gaps = 10;
          border.enable = true;
          border.width = 3;
          border.active.color =
            lib.mkForce "#${builtins.substring 1 6 colors.active_border}";
          border.inactive.color =
            lib.mkForce "#${builtins.substring 1 6 colors.inactive_border}";

          always-center-single-column = true;

          focus-ring = { enable = false; };

          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
            { proportion = 1.0; }
          ];

          default-column-width = { proportion = 1.0; };

          # Transparent background so wallpaper stays stationary in backdrop
          background-color = "transparent";

          # Tab indicator configuration
          tab-indicator = {
            enable = true;
            place-within-column = false;
          };
        };

        # Layer rules for wallpaper backdrop
        layer-rules = [{
          matches = [{ namespace = "^swww-daemon$"; }];
          place-within-backdrop = true;
        }];

        hotkey-overlay.skip-at-startup = true;

        screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

        # Environment variables
        environment = {
          XCURSOR_SIZE = "24";
          NIXOS_OZONE_WL = "1";
          NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY = "1";
        };

        # Key bindings
        binds = with config.lib.niri.actions;
          let sh = spawn "sh" "-c";
          in lib.attrsets.mergeAttrsList [{
            # Application shortcuts
            "Mod+T".action = spawn "ghostty";
            "Mod+B".action = spawn "brave";
            "Mod+C".action = spawn "code";
            "Mod+D".action = sh
              "rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi";
            "Mod+Shift+P".action =
              sh "$HOME/.local/bin/powermenu powermenu-${theme.name}";
            "Mod+Shift+T".action =
              sh "$HOME/.local/bin/themeselector powermenu-${theme.name}";
            "Mod+Shift+W".action =
              sh "$HOME/.local/bin/wallpaper ${theme.name}";
            "Mod+I".action = sh "$HOME/.local/bin/keybindings ${theme.name}";

            # Lock screen
            "Mod+Ctrl+L".action = spawn "hyprlock";

            # Screenshot
            "Mod+P".action = sh ''grim -g "$(slurp -d)" - | wl-copy'';
            "Print".action.screenshot-screen = [ ];
            #"Mod+Shift+S".action = screenshot;
            "Mod+Print".action.screenshot-window = [ ];

            # Volume control
            "XF86AudioRaiseVolume".action =
              sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+";
            "XF86AudioLowerVolume".action =
              sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-";
            "XF86AudioMute".action =
              sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "XF86AudioMicMute".action =
              sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

            # Brightness control
            "XF86MonBrightnessUp".action = sh "brightnessctl set +5%";
            "XF86MonBrightnessDown".action = sh "brightnessctl set 5%-";

            # Window management
            "Mod+Q".action = close-window;
            "Mod+F".action = fullscreen-window;
            "Mod+Shift+Space".action = toggle-window-floating;
            "Mod+W".action = toggle-column-tabbed-display;

            # Focus movement (Vi keys)
            "Mod+H".action = focus-column-left;
            "Mod+J".action = focus-window-down;
            "Mod+K".action = focus-window-up;
            "Mod+L".action = focus-column-right;

            # Focus movement (Arrow keys)
            "Mod+Left".action = focus-column-left;
            "Mod+Down".action = focus-window-down;
            "Mod+Up".action = focus-window-up;
            "Mod+Right".action = focus-column-right;

            # Move windows (Vi keys)
            "Mod+Shift+H".action = move-column-left;
            "Mod+Shift+J".action = move-window-down;
            "Mod+Shift+K".action = move-window-up;
            "Mod+Shift+L".action = move-column-right;

            # Move windows (Arrow keys)
            "Mod+Shift+Left".action = move-column-left;
            "Mod+Shift+Down".action = move-window-down;
            "Mod+Shift+Up".action = move-window-up;
            "Mod+Shift+Right".action = move-column-right;

            # Workspace switching
            "Mod+1".action.focus-workspace = 1;
            "Mod+2".action.focus-workspace = 2;
            "Mod+3".action.focus-workspace = 3;
            "Mod+4".action.focus-workspace = 4;
            "Mod+5".action.focus-workspace = 5;
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;
            "Mod+0".action.focus-workspace = 10;

            # Move to workspace
            "Mod+Shift+1".action.move-window-to-workspace = 1;
            "Mod+Shift+2".action.move-window-to-workspace = 2;
            "Mod+Shift+3".action.move-window-to-workspace = 3;
            "Mod+Shift+4".action.move-window-to-workspace = 4;
            "Mod+Shift+5".action.move-window-to-workspace = 5;
            "Mod+Shift+6".action.move-window-to-workspace = 6;
            "Mod+Shift+7".action.move-window-to-workspace = 7;
            "Mod+Shift+8".action.move-window-to-workspace = 8;
            "Mod+Shift+9".action.move-window-to-workspace = 9;
            "Mod+Shift+0".action.move-window-to-workspace = 10;

            # Column management
            "Mod+Comma".action = consume-window-into-column;
            "Mod+Period".action = expel-window-from-column;

            # Column width
            "Mod+R".action = switch-preset-column-width;
            "Mod+Shift+F".action = maximize-column;
            "Mod+Minus".action = set-column-width "-10%";
            "Mod+Plus".action = set-column-width "+10%";
            "Mod+Shift+Minus".action = set-window-height "-10%";
            "Mod+Shift+Plus".action = set-window-height "+10%";

            # Tab/group navigation
            "Mod+Tab".action = focus-window-down-or-column-right;
            "Mod+Shift+Tab".action = focus-window-up-or-column-left;

            # Overview
            "Mod+O".action = toggle-overview;

            # System
            "Mod+Shift+E".action.quit = { skip-confirmation = true; };
            "Mod+Shift+C".action = sh "niri msg action load-config-file";

            # Mouse wheel scrolling for switching windows/workspaces
            "Mod+WheelScrollDown".action = focus-column-right;
            "Mod+WheelScrollUp".action = focus-column-left;
            "Mod+Shift+WheelScrollDown".action = focus-workspace-down;
            "Mod+Shift+WheelScrollUp".action = focus-workspace-up;
          }];

        # Monitor configuration per host
        outputs = if hostName == "thinkpad" then {
          "eDP-1" = {
            mode = {
              width = 1920;
              height = 1080;
              refresh = 60.0;
            };
            position = {
              x = 0;
              y = 0;
            };
            scale = 1.0;
          };
        } else {
          "DP-2" = {
            mode = {
              width = 3840;
              height = 2160;
              refresh = 160.0;
            };
            position = {
              x = 0;
              y = 0;
            };
            scale = 1.5;
            variable-refresh-rate = true;
          };
          "HDMI-A-1" = {
            mode = {
              width = 2560;
              height = 1440;
              refresh = 100.0;
            };
            transform.rotation = 270;
            position = {
              x = 2560;
              y = 0;
            };
            variable-refresh-rate = false;
          };
        };

        # Window rules
        window-rules = [
          {
            draw-border-with-background = false;
            geometry-corner-radius = let r = 5.0;
            in {
              top-left = r;
              top-right = r;
              bottom-left = r;
              bottom-right = r;
            };
            clip-to-geometry = true;
          }
          {
            matches = [{ app-id = "^steam_app_.*$"; }];
            open-fullscreen = true;
          }
        ];

        spawn-at-startup = [
          {
            command = [
              "dbus-update-activation-environment"
              "--systemd"
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
            ];
          }
          {
            command = [
              "systemctl"
              "--user"
              "import-environment"
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
            ];
          }
          { command = [ "nm-applet" ]; }
          { command = [ "blueman-applet" ]; }
          { command = [ "${pkgs.swww}/bin/swww-daemon" "--format" "xrgb" ]; }
          {
            command = [
              "sh"
              "-c"
              "sleep 1 && ${pkgs.swww}/bin/swww img ${background}"
            ];
          }
          {
            command = [
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

      # XDG configuration for Niri/UWSM compatibility
      xdg.configFile."uwsm/env".source =
        "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

      # Waybar systemd service for niri
      systemd.user.services.waybar-niri = {
        Unit = {
          Description = "Highly customizable Wayland bar for niri";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "wayland-session@niri.target" ];
          After = [ "wayland-session@niri.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart =
            "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config.json -s %h/.config/waybar/style.css";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
        Install = { WantedBy = [ "wayland-session@niri.target" ]; };
      };

      # Udiskie systemd service for niri
      systemd.user.services.udiskie-niri = {
        Unit = {
          Description = "Udiskie";
          PartOf = [ "wayland-session@niri.target" ];
          After = [ "wayland-session@niri.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.udiskie}/bin/udiskie --tray";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
        Install = { WantedBy = [ "wayland-session@niri.target" ]; };
      };
    };
}
