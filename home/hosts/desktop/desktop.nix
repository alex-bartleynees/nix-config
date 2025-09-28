{ pkgs, ... }: {
  imports =
    [ ../../modules/vscode ../../modules/rider ../../shared/linux-desktop.nix ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    yaak
    azuredatastudio
    teams-for-linux
  ];

  services.kanshi = {
    enable = true;

    settings = [
      {
        profile = {
          name = "coding";
          outputs = [
            {
              criteria = "DP-6";
              mode = "2560x1440@165";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "DP-4";
              mode = "2560x1440@144";
              position = "2560,0";
              transform = "270";
              status = "enable";
            }
          ];
        };
      }
      {
        profile = {
          name = "gaming";
          outputs = [
            {
              criteria = "DP-6";
              mode = "2560x1440@165";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "DP-4";
              mode = "2560x1440@144";
              position = "2560,0";
              transform = "270";
              status = "disable";
            }
          ];
        };
      }
    ];
  };
}
