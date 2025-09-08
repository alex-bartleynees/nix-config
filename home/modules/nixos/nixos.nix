{ pkgs, inputs, hostName, theme, lib, ... }: {
  imports = [ ../vscode ../sway ../hyprland ../river ../rider ../linux ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    yaak
    azuredatastudio
    teams-for-linux
  ];
}
