{ pkgs, inputs, background, ... }: {
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

    ".config/sway/background".text = ''
      set $background ${background.wallpaper}
    '';
  };

  home.sessionPath = [ "$HOME/.config/rofi/scripts" ];
}
