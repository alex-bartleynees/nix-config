{ pkgs, ... }: {
  imports = [ ../wayland.nix ];
  environment.systemPackages = with pkgs; [
    river-classic
    gnome-keyring
    libsecret
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    adwaita-qt
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    adwaita-icon-theme
    udiskie
    networkmanagerapplet
    blueman
    pulseaudio
    uwsm
  ];

  programs.river-classic = { enable = true; };

  programs.uwsm = {
    enable = true;
    waylandCompositors.river = {
      binPath = "/run/current-system/sw/bin/river";
      prettyName = "River";
      comment = "River compositor with UWSM";
    };
  };

  qt = { enable = true; };

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "river";
    XDG_SESSION_DESKTOP = "river";
    #GTK_THEME = "Adwaita:dark";
    # Force dark mode for websites
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config.common.default = [ "wlr" ];
    xdgOpenUsePortal = true;
  };

  security.pam.services.hyprlock = { };

  displayManager = {
    enable = true;
    autoLogin = {
      enable = true;
      command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.river-classic}/bin/river";
    };
  };

  system.nixos.tags = [ "river" ];

}

