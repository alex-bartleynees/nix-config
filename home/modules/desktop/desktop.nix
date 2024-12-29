{ pkgs, inputs, background, hostName, ... }: {
  imports = [ ../vscode ];
  home.packages = with pkgs; [
    waybar
    swaybg
    rofi-wayland
    dunst
    swayidle
    swaylock
    sway-audio-idle-inhibit
    qbittorrent-enhanced
  ];

  home.file = {
    ".config/dunst/dunstrc".source = "${inputs.dotfiles}/configs/dunst/dunstrc";

    ".config/rofi" = {
      source = "${inputs.dotfiles}/configs/rofi";
      recursive = true;
    };

    ".config/waybar" = {
      source = "${inputs.dotfiles}/configs/waybar";
      recursive = true;
    };

    ".config/sway/colorscheme".source =
      "${inputs.dotfiles}/configs/sway/colorscheme";
    ".config/sway/config".source = "${inputs.dotfiles}/configs/sway/config";
    ".config/sway/lock.sh".source = "${inputs.dotfiles}/configs/sway/lock.sh";

    ".config/sway/background".text = ''
      set $background ${background.wallpaper}
    '';

    ".config/sway/${hostName}/config".text = ''
      set $mainMonitor DP-4
      set $secondaryMonitor DP-6
      set $lock ~/.config/sway/lock.sh

      exec swaymsg output $mainMonitor pos 0 0 res 2560x1440
      exec swaymsg output $secondaryMonitor pos 2560 0 res 2560x1440 transform 90
      exec swaymsg focus output $mainMonitor

      workspace 1 output $mainMonitor
      workspace 2 output $secondaryMonitor

      exec sway-audio-idle-inhibit

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

  home.sessionPath = [ "$HOME/.config/rofi/scripts" ];
}
