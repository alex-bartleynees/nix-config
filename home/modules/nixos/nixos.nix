{ pkgs, inputs, hostName, theme, lib, ... }: {
  imports = [ ../vscode ../rider ../linux ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    yaak
    azuredatastudio
    teams-for-linux
  ];
}
