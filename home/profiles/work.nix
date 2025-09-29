{ pkgs, hostName, ... }: {
  home.packages = with pkgs;
    lib.optionals (hostName == "desktop") [ teams-for-linux ];
}
