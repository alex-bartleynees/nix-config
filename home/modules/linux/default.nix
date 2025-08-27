{ pkgs, inputs, hostName, theme, lib, ... }: {
  imports = [ ../waybar ../rofi ../dunst ../obsidian ];
  home.packages = with pkgs; [
    firefox
    vlc
    xfce.thunar
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
  
  stylix.targets.vscode.enable = false;
}
