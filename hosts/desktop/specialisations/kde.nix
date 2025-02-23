{ config, pkgs, inputs, ... }:
let shared = import ../../../shared/nixos-default.nix { inherit inputs; };
in {
  imports = shared.getImports { additionalImports = [ ]; };
  networking.hostName = "kde";

  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
  };

  services.upower.enable = true;
  services.accounts-daemon.enable = true;

  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  environment.systemPackages = with pkgs; [
    polonium
    kdePackages.kdeplasma-addons
  ];

  # Environment variables for Wayland/NVIDIA
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  system.nixos.tags = [ "kde" ];

  # XDG Portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-kde ];
  };

  services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
  jack.enable = true;
};

}
