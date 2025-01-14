{ pkgs, inputs, background, hostName, theme, ... }: {
  home.packages = with pkgs; [
    swaybg
    swayidle
    swaylock
    sway-audio-idle-inhibit
  ];

  home.file = {
    ".config/sway/colorscheme".source =
      "${inputs.dotfiles}/themes/${theme}/sway/colorscheme";
    ".config/sway/config".source = "${inputs.dotfiles}/configs/sway/config";
    ".config/sway/lock.sh".source = "${inputs.dotfiles}/configs/sway/lock.sh";

    ".config/sway/background".text = ''
      set $background ${background.wallpaper}
    '';

    ".config/sway/${hostName}/config".text = ''
      set $mainMonitor DP-6
      set $secondaryMonitor DP-4
      set $lock ~/.config/sway/lock.sh

      exec swaymsg output $mainMonitor pos 0 0 res 2560x1440
      exec swaymsg output $secondaryMonitor pos 2560 0 res 2560x1440 transform 90
      exec swaymsg focus output $mainMonitor

      workspace 1 output $mainMonitor
      workspace 2 output $secondaryMonitor

      exec sway-audio-idle-inhibit

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
    '';
  };
}
