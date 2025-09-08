{ pkgs, ... }: {
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

  programs.river = { enable = true; };

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
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    WLR_RENDERER = "vulkan";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "river";
    XDG_SESSION_DESKTOP = "river";
    #GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
    MOZ_USE_XINPUT2 = "1";
    # Force dark mode for websites
    GTK_USE_PORTAL = "1";
    GSETTINGS_SCHEMA_DIR = "/run/current-system/sw/share/gsettings-schemas/";
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config.common.default = [ "wlr" ];
    xdgOpenUsePortal = true;
  };

  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.swaylock = { text = "auth include login"; };
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  displayManager = { enable = true; };

  system.nixos.tags = [ "river" ];

}

