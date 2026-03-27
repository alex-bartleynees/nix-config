{ lib, ... }: {
  wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
    ",2560x1440@120,0x0,1,vrr,1,cm,hdr,sdrbrightness,1.2,sdrsaturation,0.98"
  ];

  wayland.windowManager.hyprland.settings.workspace = [
    "1, monitor:HDMI-A-1, default:true"
    "2, monitor:HDMI-A-1"
    "3, monitor:HDMI-A-1"
    "4, monitor:HDMI-A-1"
    "5, monitor:HDMI-A-1"
    "6, monitor:HDMI-A-1"
    "7, monitor:HDMI-A-1"
    "8, monitor:HDMI-A-1"
    "9, monitor:HDMI-A-1"
    "10, monitor:HDMI-A-1"
  ];
}
