{
  nixosConfig = { pkgs, inputs, ... }: {
    imports = [
      ./common/wayland.nix
      ./common/wlroots.nix
      inputs.mango.nixosModules.mango
    ];

    programs.mango.enable = true;

    programs.uwsm = {
      enable = true;
      waylandCompositors.mango = {
        binPath = "/run/current-system/sw/bin/mango";
        prettyName = "Mango";
        comment = "Mango compositor with UWSM";
      };
    };

    programs.xwayland.enable = true;

    qt = { enable = true; };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals =
        [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
      config = {
        mango = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        };
      };
      xdgOpenUsePortal = true;
    };

    environment.sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Adwaita";
      XDG_CURRENT_DESKTOP = "mango";
      XDG_SESSION_DESKTOP = "mango";
    };

    displayManager = {
      enable = true;
      autoLogin = {
        enable = true;
        command =
          "${pkgs.uwsm}/bin/uwsm start /run/current-system/sw/bin/mango";
      };
    };

    system.nixos.tags = [ "mangowc" ];
  };

  homeConfig = { pkgs, lib, config, inputs, osConfig, ... }:
    let
      theme = osConfig.myConfig.theme;
      monitors = osConfig.myConfig.monitors;
      colors = theme.themeColors;
      background = theme.wallpaper;
    in {
      imports = [ ./common/linux-desktop.nix inputs.mango.hmModules.mango ];

      # Enable hypridle with theme wallpaper
      hypridle = {
        enable = true;
        wallpaper = background;
      };

      xdg.configFile."uwsm/env".source =
        "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

      wayland.windowManager.mango = {
        enable = true;
        settings = {
          # Effect
          blur = 0;
          blur_layer = 1;
          blur_optimized = 1;
          blur_params = {
            num_passes = 2;
            radius = 5;
            noise = 0.02;
            brightness = 0.9;
            contrast = 0.9;
            saturation = 1.2;
          };

          shadows = 1;
          layer_shadows = 1;
          shadow_only_floating = 1;
          shadows_size = 12;
          shadows_blur = 15;
          shadows_position = {
            x = 0;
            y = 0;
          };
          shadowscolor = "0x000000aa";

          border_radius = 5;
          no_radius_when_single = 0;
          focused_opacity = 1.0;
          unfocused_opacity = 1.0;

          # Animation Configuration
          animations = 1;
          layer_animations = 1;
          animation_type = {
            open = "zoom";
            close = "slide";
          };
          layer_animation_type = {
            open = "fade";
            close = "fade";
          };
          animation_fade_in = 1;
          animation_fade_out = 1;
          tag_animation_direction = 1;
          zoom_initial_ratio = 0.3;
          zoom_end_ratio = 0.7;
          fadein_begin_opacity = 0.6;
          fadeout_begin_opacity = 0.8;
          animation_duration = {
            move = 200;
            open = 150;
            tag = 150;
            close = 250;
          };
          animation_curve = {
            open = "0.46,1.0,0.29,1";
            move = "0.46,1.0,0.29,1";
            tag = "0.46,1.0,0.29,1";
            close = "0.08,0.92,0,1";
          };

          # Scroller Layout Setting
          scroller_structs = 10;
          scroller_default_proportion = 1;
          scroller_focus_center = 0;
          scroller_prefer_center = 1;
          edge_scroller_pointer_focus = 1;
          scroller_default_proportion_single = 1.0;
          scroller_proportion_preset = "0.5,0.8,1.0";

          # Master-Stack Layout Setting
          new_is_master = 1;
          smartgaps = 0;
          default_mfact = 0.55;
          default_nmaster = 1;
          center_master_overspread = 0;
          center_when_single_stack = 1;

          # Overview Setting
          hotarea_size = 10;
          enable_hotarea = 1;
          ov_tab_mode = 0;
          overviewgappi = 5;
          overviewgappo = 30;

          # Misc
          xwayland_persistence = 0;
          syncobj_enable = 1;
          no_border_when_single = 0;
          axis_bind_apply_timeout = 100;
          focus_on_activate = 1;
          sloppyfocus = 1;
          warpcursor = 1;
          focus_cross_monitor = 1;
          exchange_cross_monitor = 1;
          scratchpad_cross_monitor = 1;
          view_current_to_back = 1;
          enable_floating_snap = 1;
          snap_distance = 50;
          cursor_size = config.home.pointerCursor.size;
          cursor_theme = config.home.pointerCursor.name;
          cursor_hide_timeout = 0;
          drag_tile_to_tile = 0;
          single_scratchpad = 1;

          # keyboard
          repeat_rate = 25;
          repeat_delay = 600;
          numlockon = 1;
          xkb_rules_layout = "us";

          # Trackpad
          disable_trackpad = 0;
          tap_to_click = 1;
          tap_and_drag = 1;
          drag_lock = 1;
          mouse_natural_scrolling = 0;
          trackpad_natural_scrolling = 1;
          trackpad_disable_while_typing = 1;
          trackpad_left_handed = 0;
          trackpad_middle_button_emulation = 0;
          swipe_min_threshold = 20;

          # Appearance
          gappih = 10;
          gappiv = 10;
          gappoh = 10;
          gappov = 10;
          scratchpad_width_ratio = 0.8;
          scratchpad_height_ratio = 0.9;
          borderpx = 3;
          rootcolor = "0x${builtins.substring 1 6 colors.groupbar_inactive}FF";
          bordercolor = "0x${builtins.substring 1 6 colors.inactive_border}FF";
          focuscolor = "0x${builtins.substring 1 6 colors.active_border}FF";
          maximizescreencolor =
            "0x${builtins.substring 1 6 colors.locked_active}FF";
          urgentcolor = "0x${builtins.substring 1 6 colors.locked_inactive}FF";
          scratchpadcolor =
            "0x${builtins.substring 1 6 colors.groupbar_active}FF";
          globalcolor = "0x${
              builtins.substring 1 6 colors.groupbar_locked_active
            }FF";
          overlaycolor = "0x${
              builtins.substring 1 6 colors.groupbar_locked_inactive
            }FF";

          # Monitor configuration
          monitorrule = map (m:
            let
              id = if m.vendor != "" then
                "make:${m.vendor},model:${m.product},serial:${m.serial}"
              else
                "name:${m.name}";
            in "${id},width:${toString m.width},height:${
              toString m.height
            },refresh:${toString (builtins.floor m.refresh)},x:${
              toString m.x
            },y:${toString m.y},scale:${toString m.scale},vrr:${
              if m.vrr then "1" else "0"
            },rr:${
              toString
              (let q = m.transform / 90; in if q == 0 then 0 else 4 - q)
            }") monitors;

          # Tag layout rules for secondary monitors
          tagrule = lib.concatMap (m:
            if m.primary then
              [ ]
            else
              let
                tagId = if m.vendor != "" then
                  "monitor_make:${m.vendor},monitor_model:${m.product},monitor_serial:${m.serial}"
                else
                  "monitor_name:${m.name}";
              in map (id: "id:${toString id},${tagId},layout_name:vertical_tile")
              (lib.range 0 9)) monitors;

          # Environment variables
          env = [
            "XCURSOR_SIZE,${toString config.home.pointerCursor.size}"
            "XCURSOR_THEME,${config.home.pointerCursor.name}"
            "NIXOS_OZONE_WL,1"
          ];

          # Key bindings - using Alt as modifier (matching other configs)
          bind = [
            # Application shortcuts
            "ALT,SPACE,spawn,vicinae toggle"
            "ALT,T,spawn,ghostty"
            "ALT,B,spawn,brave"
            "ALT,C,spawn,code"
            "ALT,D,spawn,rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi"
            "ALT+SHIFT,P,spawn,$HOME/.local/bin/powermenu powermenu-${theme.name}"
            "ALT+SHIFT,T,spawn,$HOME/.local/bin/themeselector powermenu-${theme.name}"
            "ALT+SHIFT,W,spawn,$HOME/.local/bin/wallpaper ${theme.name}"
            "ALT,I,spawn,$HOME/.local/bin/keybindings ${theme.name}"

            # Lock screen
            "CTRL+ALT,L,spawn,hyprlock"

            # Screenshot
            ''ALT,P,spawn_shell,grim -g "$(slurp -d)" - | wl-copy''

            # Volume control
            "none,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"
            "none,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"
            "none,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            "none,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

            # Brightness control
            "none,XF86MonBrightnessUp,spawn,brightnessctl set +5%"
            "none,XF86MonBrightnessDown,spawn,brightnessctl set 5%-"

            # Window management
            "ALT,Q,killclient,"
            "ALT,F,togglefullscreen,"
            "ALT,W,toggleoverview,"
            "ALT,O,togglefloating,"

            # Focus movement (Vi keys)
            "ALT,H,focusdir,left"
            "ALT,J,focusdir,down"
            "ALT,K,focusdir,up"
            "ALT,L,focusdir,right"

            # Focus movement (Arrow keys)
            "ALT,Left,focusdir,left"
            "ALT,Down,focusdir,down"
            "ALT,Up,focusdir,up"
            "ALT,Right,focusdir,right"

            # Move windows (Vi keys)
            "ALT+SHIFT,H,exchange_client,left"
            "ALT+SHIFT,J,exchange_client,down"
            "ALT+SHIFT,K,exchange_client,up"
            "ALT+SHIFT,L,exchange_client,right"

            # Move windows (Arrow keys)
            "ALT+SHIFT,Left,exchange_client,left"
            "ALT+SHIFT,Down,exchange_client,down"
            "ALT+SHIFT,Up,exchange_client,up"
            "ALT+SHIFT,Right,exchange_client,right"

            # Move windows between monitors (Vi keys)
            "ALT+SUPER,H,tagmon,left,1"
            "ALT+SUPER,J,tagmon,down,1"
            "ALT+SUPER,K,tagmon,up,1"
            "ALT+SUPER,L,tagmon,right,1"

            # Move windows between monitors (Arrow keys)
            "ALT+SUPER,Left,tagmon,left,1"
            "ALT+SUPER,Down,tagmon,down,1"
            "ALT+SUPER,Up,tagmon,up,1"
            "ALT+SUPER,Right,tagmon,right,1"

            # Workspace switching (tags in Mango)
            "ALT,1,view,1"
            "ALT,2,view,2"
            "ALT,3,view,3"
            "ALT,4,view,4"
            "ALT,5,view,5"
            "ALT,6,view,6"
            "ALT,7,view,7"
            "ALT,8,view,8"
            "ALT,9,view,9"
            "ALT,0,view,0"

            # Move to workspace
            "ALT+SHIFT,1,tag,1"
            "ALT+SHIFT,2,tag,2"
            "ALT+SHIFT,3,tag,3"
            "ALT+SHIFT,4,tag,4"
            "ALT+SHIFT,5,tag,5"
            "ALT+SHIFT,6,tag,6"
            "ALT+SHIFT,7,tag,7"
            "ALT+SHIFT,8,tag,8"
            "ALT+SHIFT,9,tag,9"
            "ALT+SHIFT,0,tag,0"

            # Layout management
            "ALT,R,switch_layout,"
            "ALT,S,setlayout,scroller"
            "ALT,E,switch_proportion_preset,"
            "ALT+SHIFT,F,togglemaximizescreen,"
            "ALT,comma,setmfact,-5"
            "ALT,period,setmfact,+5"
            "ALT,Return,zoom,"

            # Tab/group navigation
            "ALT,Tab,focusstack,next"
            "ALT+SHIFT,Tab,focusstack,prev"

            # Scratchpad
            "ALT+CTRL,I,minimized,"
            "ALT,Z,toggle_scratchpad,"
            "ALT+CTRL,O,restore_minimized,"

            # System
            "ALT+SHIFT,E,quit,"
            "ALT+SHIFT,C,reload_config,"
          ];

          # Mouse bindings
          mousebind = [
            "ALT,btn_left,moveresize,curmove"
            "ALT,btn_right,moveresize,curresize"
            "NONE,btn_middle,togglemaximizescreen,0"
          ];

          # Gestures
          gesturebind = [
            "none,left,3,focusdir,left"
            "none,right,3,focusdir,right"
            "none,up,3,focusdir,up"
            "none,down,3,focusdir,down"
            "none,left,4,viewtoleft_have_client"
            "none,right,4,viewtoright_have_client"
            "none,up,4,toggleoverview"
            "none,down,4,toggleoverview"
          ];

          # Axis bindings (mouse wheel)
          axisbind = [
            "ALT,UP,focusdir,left"
            "ALT,DOWN,focusdir,right"
            "ALT+SHIFT,UP,viewtoleft_have_client"
            "ALT+SHIFT,DOWN,viewtoright_have_client"
          ];

          # Window rules for steam games
          windowrule = [ "isfullscreen:1,appid:^steam_app_.*$" ];
        };
        autostart_sh = ''
          # UWSM finalize for proper session management - export all critical Wayland variables
          uwsm finalize SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &

          # Network manager applet
          nm-applet &

          # Bluetooth applet
          blueman-applet &

          # Clipboard manager
          wl-clip-persist --clipboard regular --reconnect-tries 0 &

          # Desktop portal (for obs and screen sharing)
          dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
          systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        '';
      };

      vicinae.enable = true;

      waybar.sessionTarget = "graphical-session.target";

      udiskie.enable = true;

      awww = {
        enable = true;
        wallpaper = background;
      };
    };
}
