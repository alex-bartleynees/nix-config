{ pkgs, ... }: {
  # Common Wayland session variables shared across desktop environments
  environment.sessionVariables = {
    # Enable Wayland support for Chromium/Electron apps
    NIXOS_OZONE_WL = "1";

    # Set session type to Wayland
    XDG_SESSION_TYPE = "wayland";

    # Enable GTK portal integration (needed for GTK3 apps)
    GTK_USE_PORTAL = "1";

    WLR_DRM_NO_ATOMIC = "1";
  };

  # Common system packages for Wayland desktop environments (universal)
  environment.systemPackages = with pkgs; [
    # Authentication and secrets
    gnome-keyring
    libsecret

    # Universal XDG portals for Wayland
    xdg-desktop-portal
    xdg-desktop-portal-gtk

    # System utilities
    udiskie
    networkmanagerapplet
    blueman
    pulseaudio

    # Qt/GTK theming packages
    adwaita-qt
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    adwaita-icon-theme
  ];
}
