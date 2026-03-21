{ pkgs, lib, ... }: {
  wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
    "DP-2,3840x2160@160,0x0,1.5,vrr,1"
    "HDMI-A-1,2560x1440@100,2560x0,1,transform,3,vrr,1"
  ];

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
