{ pkgs, lib, ... }: {
  wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
    "DP-2,3840x2160@160,0x0,1.5,vrr,1"
    "HDMI-A-1,2560x1440@100,2560x0,1,transform,3,vrr,1"
  ];

  wayland.windowManager.hyprland.settings.windowrule =
    [ "monitor DP-2, match:class ^(steam_app_.*)$" ];

  wayland.windowManager.hyprland.settings.workspace = [
    "1, monitor:DP-2"
    "2, monitor:DP-2"
    "3, monitor:DP-2"
    "4, monitor:DP-2"
    "5, monitor:DP-2"
    "6, monitor:HDMI-A-1, layoutopt:direction:down"
    "7, monitor:HDMI-A-1, layoutopt:direction:down"
    "8, monitor:HDMI-A-1, layoutopt:direction:down"
    "9, monitor:HDMI-A-1, layoutopt:direction:down"
    "10, monitor:HDMI-A-1, layoutopt:direction:down"
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
