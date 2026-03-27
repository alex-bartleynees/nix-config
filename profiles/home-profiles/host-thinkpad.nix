{ pkgs, lib, ... }: {
  wayland.windowManager.hyprland.settings.monitor =
    lib.mkForce [ "eDP-1,1920x1080@60,0x0,1" ];

  wayland.windowManager.hyprland.settings.workspace = [
    "1, monitor:eDP-1"
    "2, monitor:eDP-1"
    "3, monitor:eDP-1"
    "4, monitor:eDP-1"
    "5, monitor:eDP-1"
    "6, monitor:eDP-1"
    "7, monitor:eDP-1"
    "8, monitor:eDP-1"
    "9, monitor:eDP-1"
    "10, monitor:eDP-1"
  ];

  services.kanshi = {
    enable = true;
    systemdTarget = "river-session.target";

    settings = [{
      profile = {
        name = "docked";
        outputs = [
          {
            criteria = "eDP-1"; # eDP-1 (laptop)
            mode = "1920x1080@60";
            position = "0,1440";
            status = "enable";
          }
          {
            criteria = "DP-1"; # DP-1 (external)
            mode = "2560x1440@60";
            position = "0,0";
            status = "enable";
          }
        ];
      };
    }];
  };
}
