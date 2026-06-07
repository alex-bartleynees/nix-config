{ pkgs, lib, ... }: {
  wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
    "desc:AOC U27G4 10GR2HA001383,3840x2160@160,0x0,1.5,vrr,1"
    "desc:LG Electronics 27GL850 006NTDVG0786,2560x1440@100,2560x0,1,transform,3,vrr,1"
  ];

  wayland.windowManager.hyprland.settings.windowrule =
    [ "monitor desc:AOC U27G4 10GR2HA001383, match:class ^(steam_app_.*)$" ];

  wayland.windowManager.hyprland.settings.workspace = [
    "1, monitor:desc:AOC U27G4 10GR2HA001383, default:true"
    "2, monitor:desc:AOC U27G4 10GR2HA001383"
    "3, monitor:desc:AOC U27G4 10GR2HA001383"
    "4, monitor:desc:AOC U27G4 10GR2HA001383"
    "5, monitor:desc:AOC U27G4 10GR2HA001383"
    "6, monitor:desc:LG Electronics 27GL850 006NTDVG0786, layoutopt:direction:down, default:true"
    "7, monitor:desc:LG Electronics 27GL850 006NTDVG0786, layoutopt:direction:down"
    "8, monitor:desc:LG Electronics 27GL850 006NTDVG0786, layoutopt:direction:down"
    "9, monitor:desc:LG Electronics 27GL850 006NTDVG0786, layoutopt:direction:down"
    "10, monitor:desc:LG Electronics 27GL850 006NTDVG0786, layoutopt:direction:down"
  ];

  services.kanshi = {
    enable = true;

    settings = [
      {
        profile = {
          name = "coding";
          outputs = [
            {
              criteria = "AOC U27G4 10GR2HA001383";
              mode = "3840x2160@160";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "LG Electronics 27GL850 006NTDVG0786";
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
              criteria = "AOC U27G4 10GR2HA001383";
              mode = "3840x2160@160";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "LG Electronics 27GL850 006NTDVG0786";
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
