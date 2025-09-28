{ pkgs, ... }: {
  imports = [ ../wayland.nix ];
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
  };

  services.upower.enable = true;
  services.accounts-daemon.enable = true;

  programs.nm-applet.enable = true;

  environment.systemPackages = with pkgs; [
    polonium
    kdePackages.kdeplasma-addons
  ];


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
