{ pkgs, ... }: {
  services.kanshi = {
    enable = true;

    settings = [
      {
        profile = {
          name = "coding";
          outputs = [
            {
              criteria = "DP-2";
              mode = "3840x2160@160";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "HDMI-A-1";
              mode = "2560x1440@100";
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
              criteria = "DP-2";
              mode = "3840x2160@160";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "HDMI-A-1";
              mode = "2560x1440@100";
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
