{ config, pkgs, inputs, ... }:
let shared = import ../../../shared/nixos-default.nix { inherit inputs; };
in {
  imports = shared.getImports { additionalImports = [ ]; };

  networking.hostName = "gnome";

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;
  };

  services.gnome = {
    core-utilities.enable = true;
    gnome-keyring.enable = true;
  };

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.gnome-shell-extensions
  ];

  services.upower.enable = true;
  services.accounts-daemon.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  system.nixos.tags = [ "gnome" ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

}
