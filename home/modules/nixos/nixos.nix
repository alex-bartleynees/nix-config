{ pkgs, inputs, background, hostName, theme, lib, ... }: {
  imports = [
    ../vscode
    ../waybar
    ../sway
    ../hyprland
    ../rofi
    ../dunst
    ../rider
    ../obsidian
  ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    firefox
    grim
    slurp
    feh
    vlc
    nautilus
    ghostty
    pavucontrol
    pulsemixer
  ];

  programs.brave = { enable = true; };

  home.pointerCursor = {
    name = lib.mkDefault "Adwaita";
    package = lib.mkDefault pkgs.adwaita-icon-theme;
    size = lib.mkDefault 24;
    x11.enable = true;
  };

  home.file = { ".config/ghostty/config".source = ../ghostty/ghostty.linux; };

  fonts.fontconfig.enable = true;
}
