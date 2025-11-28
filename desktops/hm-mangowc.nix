{ pkgs, config, hostName, theme, inputs, ... }:
let
  colors = theme.themeColors;
  background = theme.wallpaper;

in {
  imports = [ ./common/hm-linux-desktop.nix inputs.mango.hmModules.mango ];

  # Enable hypridle with theme wallpaper
  hypridle = {
    enable = true;
    wallpaper = background;
  };

  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  wayland.windowManager.mango = {
    enable = true;
    settings = ''
      # Effect
      blur=0
      blur_layer=1
      blur_optimized=1
      blur_params_num_passes=2
      blur_params_radius=5
      blur_params_noise=0.02
      blur_params_brightness=0.9
      blur_params_contrast=0.9
      blur_params_saturation=1.2

      shadows=1
      layer_shadows=1
      shadow_only_floating=1
      shadows_size=12
      shadows_blur=15
      shadows_position_x=0
      shadows_position_y=0
      shadowscolor=0x000000aa

      border_radius=5
      no_radius_when_single=0
      focused_opacity=1.0
      unfocused_opacity=1.0

      # Animation Configuration
      animations=1
      layer_animations=1
      animation_type_open=zoom
      animation_type_close=slide
      layer_animation_type_open=fade
      layer_animation_type_close=fade
      animation_fade_in=1
      animation_fade_out=1
      tag_animation_direction=1
      zoom_initial_ratio=0.3
      zoom_end_ratio=0.7
      fadein_begin_opacity=0.6
      fadeout_begin_opacity=0.8
      animation_duration_move=200
      animation_duration_open=150
      animation_duration_tag=150
      animation_duration_close=250
      animation_curve_open=0.46,1.0,0.29,1
      animation_curve_move=0.46,1.0,0.29,1
      animation_curve_tag=0.46,1.0,0.29,1
      animation_curve_close=0.08,0.92,0,1

      # Scroller Layout Setting
      scroller_structs=10
      scroller_default_proportion=1
      scroller_focus_center=0
      scroller_prefer_center=1
      edge_scroller_pointer_focus=1
      scroller_default_proportion_single=1.0
      scroller_proportion_preset=0.5,0.8,1.0

      # Master-Stack Layout Setting
      new_is_master=1
      smartgaps=0
      default_mfact=0.55
      default_smfact=0.55
      default_nmaster=1
      center_master_overspread=0
      center_when_single_slave=1

      # Overview Setting
      hotarea_size=10
      enable_hotarea=1
      ov_tab_mode=0
      overviewgappi=5
      overviewgappo=30

      # Misc
      adaptive_sync=0
      xwayland_persistence=0
      syncobj_enable=1
      no_border_when_single=0
      axis_bind_apply_timeout=100
      focus_on_activate=1
      inhibit_regardless_of_visibility=0
      sloppyfocus=1
      warpcursor=1
      focus_cross_monitor=1
      exchange_cross_monitor=1
      scratchpad_cross_monitor=1
      focus_cross_tag=0
      view_current_to_back=1
      enable_floating_snap=1
      snap_distance=50
      cursor_size=${toString config.home.pointerCursor.size}
      cursor_theme=${config.home.pointerCursor.name}
      cursor_hide_timeout=0
      drag_tile_to_tile=0
      single_scratchpad=1

      # keyboard
      repeat_rate=25
      repeat_delay=600
      numlockon=1
      xkb_rules_layout=us

      # Trackpad
      disable_trackpad=0
      tap_to_click=1
      tap_and_drag=1
      drag_lock=1
      mouse_natural_scrolling=0
      trackpad_natural_scrolling=1
      disable_while_typing=1
      left_handed=0
      middle_button_emulation=0
      swipe_min_threshold=20
      accel_profile=2
      accel_speed=0.0

      # Appearance
      gappih=10
      gappiv=10
      gappoh=10
      gappov=10
      scratchpad_width_ratio=0.8
      scratchpad_height_ratio=0.9
      borderpx=3
      rootcolor=0x${builtins.substring 1 6 colors.groupbar_inactive}FF
      bordercolor=0x${builtins.substring 1 6 colors.inactive_border}FF
      focuscolor=0x${builtins.substring 1 6 colors.active_border}FF
      maxmizescreencolor=0x${builtins.substring 1 6 colors.locked_active}FF
      urgentcolor=0x${builtins.substring 1 6 colors.locked_inactive}FF
      scratchpadcolor=0x${builtins.substring 1 6 colors.groupbar_active}FF
      globalcolor=0x${builtins.substring 1 6 colors.groupbar_locked_active}FF
      overlaycolor=0x${builtins.substring 1 6 colors.groupbar_locked_inactive}FF

      # Monitor configuration
      ${if hostName == "thinkpad" then ''
        monitorrule=eDP-1,0.55,1,tile,0,1,0,0,1920,1080,60
      '' else ''
        monitorrule=DP-6,0.55,1,tile,0,1,0,0,2560,1440,165
        monitorrule=DP-4,0.55,1,vertical_tile,1,1,2560,0,2560,1440,144
      ''}

      # Environment variables
      env=XCURSOR_SIZE,${toString config.home.pointerCursor.size}
      env=XCURSOR_THEME,${config.home.pointerCursor.name}
      env=NIXOS_OZONE_WL,1

      # Key bindings - using Alt as modifier (matching other configs)
      # Application shortcuts
      bind=ALT,T,spawn,ghostty
      bind=ALT,B,spawn,brave
      bind=ALT,C,spawn,code
      bind=ALT,D,spawn,rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi
      bind=ALT+SHIFT,P,spawn,$HOME/.local/bin/powermenu powermenu-${theme.name}
      bind=ALT+SHIFT,T,spawn,$HOME/.local/bin/themeselector powermenu-${theme.name}
      bind=ALT+SHIFT,W,spawn,$HOME/.local/bin/wallpaper ${theme.name}
      bind=ALT,I,spawn,$HOME/.local/bin/keybindings ${theme.name}

      # Lock screen
      bind=CTRL+ALT,L,spawn,hyprlock

      # Screenshot
      bind=ALT,P,spawn_shell,grim -g "\$(slurp)" - | wl-copy
      bind=none,Print,spawn,grim
      bind=ALT+SHIFT,S,spawn_shell,grim -g "\$(slurp)" - | wl-copy

      # Volume control
      bind=none,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+
      bind=none,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-
      bind=none,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind=none,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # Brightness control
      bind=none,XF86MonBrightnessUp,spawn,brightnessctl set +5%
      bind=none,XF86MonBrightnessDown,spawn,brightnessctl set 5%-

      # Window management
      bind=ALT,Q,killclient,
      bind=ALT,F,togglefullscreen,
      bind=ALT,W,toggleoverview,
      bind=ALT,O,togglefloating,

      # Focus movement (Vi keys)
      bind=ALT,H,focusdir,left
      bind=ALT,J,focusdir,down
      bind=ALT,K,focusdir,up
      bind=ALT,L,focusdir,right

      # Focus movement (Arrow keys)
      bind=ALT,Left,focusdir,left
      bind=ALT,Down,focusdir,down
      bind=ALT,Up,focusdir,up
      bind=ALT,Right,focusdir,right

      # Move windows (Vi keys)
      bind=ALT+SHIFT,H,exchange_client,left
      bind=ALT+SHIFT,J,exchange_client,down
      bind=ALT+SHIFT,K,exchange_client,up
      bind=ALT+SHIFT,L,exchange_client,right

      # Move windows (Arrow keys)
      bind=ALT+SHIFT,Left,exchange_client,left
      bind=ALT+SHIFT,Down,exchange_client,down
      bind=ALT+SHIFT,Up,exchange_client,up
      bind=ALT+SHIFT,Right,exchange_client,right

      # Move windows between monitors (Vi keys)
      bind=ALT+SUPER,H,tagmon,left,1
      bind=ALT+SUPER,J,tagmon,down,1
      bind=ALT+SUPER,K,tagmon,up,1
      bind=ALT+SUPER,L,tagmon,right,1

      # Move windows between monitors (Arrow keys)
      bind=ALT+SUPER,Left,tagmon,left,1
      bind=ALT+SUPER,Down,tagmon,down,1
      bind=ALT+SUPER,Up,tagmon,up,1
      bind=ALT+SUPER,Right,tagmon,right,1

      # Workspace switching (tags in Mango)
      bind=ALT,1,view,1
      bind=ALT,2,view,2
      bind=ALT,3,view,3
      bind=ALT,4,view,4
      bind=ALT,5,view,5
      bind=ALT,6,view,6
      bind=ALT,7,view,7
      bind=ALT,8,view,8
      bind=ALT,9,view,9
      bind=ALT,0,view,0

      # Move to workspace
      bind=ALT+SHIFT,1,tag,1
      bind=ALT+SHIFT,2,tag,2
      bind=ALT+SHIFT,3,tag,3
      bind=ALT+SHIFT,4,tag,4
      bind=ALT+SHIFT,5,tag,5
      bind=ALT+SHIFT,6,tag,6
      bind=ALT+SHIFT,7,tag,7
      bind=ALT+SHIFT,8,tag,8
      bind=ALT+SHIFT,9,tag,9
      bind=ALT+SHIFT,0,tag,0

      # Layout management
      bind=ALT,R,switch_layout,
      bind=ALT,S,setlayout,scroller
      bind=ALT,E,switch_proportion_preset,
      bind=ALT+SHIFT,F,togglemaxmizescreen,
      bind=ALT,comma,setmfact,-5
      bind=ALT,period,setmfact,+5
      bind=ALT,Return,zoom,

      # Tab/group navigation
      bind=ALT,Tab,focusstack,next
      bind=ALT+SHIFT,Tab,focusstack,prev

      # Scratchpad
      bind=ALT+CTRL,I,minimized,
      bind=ALT,Z,toggle_scratchpad,
      bind=ALT+CTRL,O,restore_minimized,

      # System
      bind=ALT+SHIFT,E,quit,
      bind=ALT+SHIFT,C,reload_config,

      # Mouse bindings
      mousebind=ALT,btn_left,moveresize,curmove
      mousebind=ALT,btn_right,moveresize,curresize
      mousebind=NONE,btn_middle,togglemaxmizescreen,0

      # Gestures
      gesturebind=none,left,3,focusdir,left
      gesturebind=none,right,3,focusdir,right
      gesturebind=none,up,3,focusdir,up
      gesturebind=none,down,3,focusdir,down
      gesturebind=none,left,4,viewtoleft_have_client
      gesturebind=none,right,4,viewtoright_have_client
      gesturebind=none,up,4,toggleoverview
      gesturebind=none,down,4,toggleoverview

      # Axis bindings (mouse wheel)
      axisbind=ALT,UP,viewtoleft_have_client
      axisbind=ALT,DOWN,viewtoright_have_client

      # Window rules for steam games
      windowrule=isfullscreen:1,appid:^steam_app_.*$
    '';
    autostart_sh = ''
      # UWSM finalize for proper session management - export all critical Wayland variables
      uwsm finalize SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &

      # Network manager applet
      nm-applet &

      # Bluetooth applet
      blueman-applet &

      # Wallpaper with swww
      ${pkgs.swww}/bin/swww-daemon --format xrgb &
      sleep 1 && ${pkgs.swww}/bin/swww img ${background} &

      # Clipboard manager
      wl-clip-persist --clipboard regular --reconnect-tries 0 &
      wl-paste --type text --watch cliphist store &

      # Desktop portal (for obs and screen sharing)
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    '';
  };

  # Waybar systemd service for mango
  systemd.user.services.waybar-mango = {
    Unit = {
      Description = "Highly customizable Wayland bar for mango";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config.json -s %h/.config/waybar/style.css";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  # Udiskie systemd service for mango
  systemd.user.services.udiskie-mango = {
    Unit = {
      Description = "Udiskie";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.udiskie}/bin/udiskie --tray";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
