{ pkgs, ... }: {
  imports = [
    ../wayland.nix
    ../wayland-packages.nix
    ../wayland-system.nix
  ];
  services.desktopManager = { gnome.enable = true; };

  services.displayManager = {
    gdm.enable = true;
    gdm.wayland = true;
  };

  services.gnome = {
    core-apps.enable = true;
    gnome-keyring.enable = true;
  };

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    dconf-editor
    gnome-shell-extensions
  ];

  services.upower.enable = true;
  services.accounts-daemon.enable = true;


  system.nixos.tags = [ "gnome" ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${
      pkgs.writeText "gdm-monitors.xml" ''
          <monitors version="2">
          <configuration>
            <layoutmode>physical</layoutmode>
            <logicalmonitor>
              <x>0</x>
              <y>347</y>
              <scale>1</scale>
              <primary>yes</primary>
              <monitor>
                <monitorspec>
                  <connector>DP-6</connector>
                  <vendor>GSM</vendor>
                  <product>LG ULTRAGEAR</product>
                  <serial>312NTRL3F958</serial>
                </monitorspec>
                <mode>
                  <width>2560</width>
                  <height>1440</height>
                  <rate>164.958</rate>
                </mode>
              </monitor>
            </logicalmonitor>
            <logicalmonitor>
              <x>2560</x>
              <y>0</y>
              <scale>1</scale>
              <transform>
                <rotation>right</rotation>
                <flipped>no</flipped>
              </transform>
              <monitor>
                <monitorspec>
                  <connector>DP-4</connector>
                  <vendor>GSM</vendor>
                  <product>27GL850</product>
                  <serial>006NTDVG0786</serial>
                </monitorspec>
                <mode>
                  <width>2560</width>
                  <height>1440</height>
                  <rate>144.000</rate>
                </mode>
              </monitor>
            </logicalmonitor>
          </configuration>
        </monitors>
      ''
    }"
  ];
}
