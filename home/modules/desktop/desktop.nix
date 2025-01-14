{ pkgs, inputs, background, hostName, theme, ... }: {
  imports = [ ../vscode ../waybar ../sway ../rofi ../dunst ];
  home.packages = with pkgs; [ qbittorrent-enhanced ];
}
