{ pkgs, ... }: {
  imports =
    [ ../../modules/vscode ../../modules/rider ../../modules/linux-packages ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    yaak
    azuredatastudio
    teams-for-linux
  ];

  services.kanshi = {
    enable = true;

    profiles = {
      coding = {
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
            status = "enable";
          }
        ];
      };

      gaming = {
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
            status = "disable";
          }
        ];
      };
    };
  };
}
