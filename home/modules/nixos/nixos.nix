{ pkgs, inputs, hostName, theme, lib, ... }: {
  imports = [
    ../vscode
    ../waybar
    ../sway
    ../hyprland
    ../rofi
    ../dunst
    ../rider
    ../obsidian
    ../linux
  ];
  home.packages = with pkgs; [ qbittorrent-enhanced ];
}
