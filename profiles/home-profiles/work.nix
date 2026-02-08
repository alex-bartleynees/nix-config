{ pkgs, ... }: {
  home.packages = with pkgs; [
    teams-for-linux
    openfortivpn
    openfortivpn-webview
  ];
}