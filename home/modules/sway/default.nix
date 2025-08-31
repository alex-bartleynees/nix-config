{ pkgs, inputs, hostName, theme, ... }: {
  home.packages = with pkgs; [
    swaybg
    swayidle
    swaylock
    sway-audio-idle-inhibit
    grim
    slurp
    feh
  ];

  home.file = {
    ".config/sway/colorscheme".source =
      "${inputs.dotfiles}/themes/${theme.name}/sway/colorscheme";
    ".config/sway/config".source = "${inputs.dotfiles}/configs/sway/config";
    ".config/sway/lock.sh".source = "${inputs.dotfiles}/configs/sway/lock.sh";

    ".config/sway/background".text = ''
      set $background ${theme.wallpaper}
    '';

    ".config/sway/${hostName}/config".text = ''
      set $mainMonitor '"LG Electronics LG ULTRAGEAR 312NTRL3F958"'
      set $secondaryMonitor '"LG Electronics 27GL850 006NTDVG0786"'
      output * adaptive_sync on
      set $lock ~/.config/sway/lock.sh

      exec swaymsg output $mainMonitor pos 0 0 res 2560x1440
      exec swaymsg output $secondaryMonitor pos 2560 0 res 2560x1440 transform 90
      exec swaymsg focus output $mainMonitor
      exec swaymsg output $mainMonitor adaptive_sync on

      exec sway-audio-idle-inhibit

      # Start waybar with Sway-specific config
      exec waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css

      # Initialize uwsm for proper session management and environment variable handling
      exec uwsm finalize SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME

      # Prevent idle during Steam Remote Play
      for_window [class="steam_app_streaming_client"] inhibit_idle focus
      for_window [class="steamwebhelper"] inhibit_idle focus
      for_window [class="steam"] inhibit_idle focus
      for_window [title="^Steam Big Picture Mode$"] inhibit_idle focus
      for_window [class="^steam$"] inhibit_idle focus
      for_window [class="^steam_app.*"] inhibit_idle focus
      for_window [class="^Steam$"] inhibit_idle focus


      # Idle configuration
      exec swayidle \
          timeout 300 'exec $lock' \
          timeout 600 'swaymsg "output $mainMonitor dpms off"; swaymsg "output $secondaryMonitor dpms off"' \
          after-resume 'swaymsg "output $mainMonitor dpms on"; swaymsg "output $secondaryMonitor dpms on"' \
          before-sleep 'exec $lock; swaymsg "output $mainMonitor dpms off"; swaymsg "output $secondaryMonitor dpms off"'

      # Wake command
      bindsym $mod+Shift+w exec swaymsg "output $mainMonitor dpms on; output $secondaryMonitor dpms on"


      # start rofi (a program launcher)
      bindsym $mod+d exec rofi -show drun -theme $HOME/.config/rofi/themes/colors/${theme.name}.rasi
      # start rofi powermenu
      bindsym $mod+shift+p exec $HOME/.local/bin/powermenu powermenu-${theme.name}

      input * {
        xkb_layout "us,us"
      }
    '';
  };
}
