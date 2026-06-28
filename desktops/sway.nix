{
  nixosConfig = { pkgs, ... }: {
    imports = [ ./common/wayland.nix ./common/wlroots.nix ];

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraSessionCommands = ''
        export ZDOTDIR=''${HOME}
        export SHELL=${pkgs.zsh}/bin/zsh
        source "''${HOME}/.zshenv"
        ZSH_DISABLE_COMPFIX=true
        DISABLE_AUTO_UPDATE=true
      '';

      extraOptions = [ "--unsupported-gpu" ];
    };

    # Enable uwsm for sway session management
    programs.uwsm = {
      enable = true;
      waylandCompositors.sway = {
        binPath = "/run/current-system/sw/bin/sway";
        prettyName = "Sway";
        comment = "Sway compositor with UWSM";
      };
    };

    qt = {
      enable = true;
      #platformTheme = "gtk2";
      #style = "adwaita-dark";
    };

    programs.xwayland.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals =
        [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
      config.common.default = [ "wlr" ];
      xdgOpenUsePortal = true;
    };

    displayManager = { enable = true; };

    system.nixos.tags = [ "sway" ];
  };

  homeConfig = { pkgs, config, lib, theme, monitors, ... }:
    let
      colors = theme.themeColors;
      background = theme.wallpaper;
      toSwayRef = m: if m.description != "" then m.description else m.name;
      primaryMonitor = builtins.head (builtins.filter (m: m.primary) monitors);
      secondaryMonitors = builtins.filter (m: !m.primary) monitors;
      hasSecondary = secondaryMonitors != [ ];
      secondaryMonitor = if hasSecondary then
        builtins.head secondaryMonitors
      else
        primaryMonitor;
    in {
      imports = [ ./common/linux-desktop.nix ];
      home.packages = with pkgs; [
        swaybg
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
              "${modifier}+i" =
                "exec $HOME/.local/bin/keybindings ${theme.name}";

              # Screenshot
              "${modifier}+p" = ''exec grim -g "$(slurp -d)" - | wl-copy'';

              # Lock screen
              "Control+${modifier}+l" = "exec ~/.local/bin/lock.sh";

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
              "XF86AudioMute" =
                "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
              "XF86AudioMicMute" =
                "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

              # Brightness controls
              "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
              "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

              # Wake displays
              "Control+${modifier}+w" = "exec " + lib.concatMapStringsSep "; "
                (m: ''swaymsg "output \"${toSwayRef m}\" dpms on"'') monitors;
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

          output = lib.listToAttrs (map (m: {
            name = toSwayRef m;
            value = {
              mode = "${toString m.width}x${toString m.height}@${
                  toString (builtins.floor m.refresh)
                }Hz";
              position = "${toString m.x},${toString m.y}";
              background = "${background} fill";
            } // lib.optionalAttrs (m.scale != 1.0) {
              scale = toString m.scale;
            } // lib.optionalAttrs m.vrr { adaptive_sync = "on"; }
              // lib.optionalAttrs (m.transform != 0) {
                transform = toString m.transform;
              };
          }) monitors);

          workspaceOutputAssign = let
            mkAssign = ws: output: {
              workspace = toString ws;
              output = output;
            };
            primaryWS = map (i: mkAssign i primaryMonitor.name) (lib.range 1 5);
            secondaryWS =
              map (i: mkAssign i secondaryMonitor.name) (lib.range 6 10);
          in if hasSecondary then
            primaryWS ++ secondaryWS
          else
            map (i: mkAssign i primaryMonitor.name) (lib.range 1 10);

          # Startup applications
          startup = [
            {
              command =
                "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
            }
            { command = "nm-applet"; }
            { command = "blueman-applet"; }
            { command = "sway-audio-idle-inhibit"; }
            { command = "autotiling-rs"; }
            {
              command =
                "uwsm finalize SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME";
            }
          ];

          # Disable default sway bar
          bars = [ ];
        };
      };

      # Swayidle + swaylock via shared module
      swayidle = {
        enable = true;
        wallpaper = background;
        displayOffCommand = lib.concatMapStringsSep "; "
          (m: ''${pkgs.sway}/bin/swaymsg "output \"${toSwayRef m}\" dpms off"'')
          monitors;
        displayOnCommand = lib.concatMapStringsSep "; "
          (m: ''${pkgs.sway}/bin/swaymsg "output \"${toSwayRef m}\" dpms on"'')
          monitors;
        preLockScript = ''
          export SWAYSOCK=/run/user/$(${pkgs.coreutils}/bin/id -u)/sway-ipc.$(${pkgs.coreutils}/bin/id -u).$(${pkgs.procps}/bin/pgrep -x sway).sock
          export WAYLAND_DISPLAY=wayland-1
        '';
      };

      waybar.sessionTarget = "sway-session.target";

      udiskie = {
        enable = true;
        sessionTarget = "sway-session.target";
      };

      awww = {
        enable = true;
        sessionTarget = "sway-session.target";
        wallpaper = background;
      };

      # XDG configuration for UWSM
      xdg.configFile."uwsm/env".source =
        "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
    };
}
