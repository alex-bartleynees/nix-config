{ pkgs, ... }: {
  imports =
    [ ../../modules/vscode ../../modules/rider ../../modules/linux-packages ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    yaak
    azuredatastudio
    teams-for-linux
  ];
}
