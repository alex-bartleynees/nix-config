{ config, pkgs, ... }: {
  services.xserver.videoDrivers = [ "nvidia" ];
  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [
    pkgs.gnome-keyring
    pkgs.xdg-desktop-portal
  ];
  services.blueman.enable = true;
  services.upower.enable = true;
  services.acpid.enable = true;
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };
  services.udisks2.enable = true;

  services.gnome.gnome-keyring.enable = true;

  services.udev.extraRules = ''
    # Enable wake from USB devices
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="enabled"

    # Enable wake from specific USB ports (XHCI controller)
    SUBSYSTEM=="pci", ATTRS{vendor}=="0x8086", ATTRS{device}=="0x8c31", ATTR{power/wakeup}="enabled"
  '';
}
