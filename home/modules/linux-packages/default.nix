{ pkgs, lib, ... }: {
  imports =
    [ ../waybar ../rofi ../dunst ../obsidian ../ghostty ../brave ../alacritty ];
  home.packages = with pkgs; [
    firefox
    vlc
    xfce.thunar
    pavucontrol
    pulsemixer
    xfce.tumbler
    xfce.ristretto
    wdisplays
  ];

  home.pointerCursor = {
    name = lib.mkDefault "Adwaita";
    package = lib.mkDefault pkgs.adwaita-icon-theme;
    size = lib.mkDefault 24;
    x11.enable = true;
  };

  fonts.fontconfig.enable = true;

  stylix.targets.vscode.enable = false;
}
