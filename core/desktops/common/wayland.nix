{ pkgs, ... }: {
  # Common Wayland session variables shared across desktop environments
  environment.sessionVariables = {
    # Enable Wayland support for Chromium/Electron apps
    NIXOS_OZONE_WL = "1";

    # Disable hardware cursors (fixes cursor issues on some hardware)
    WLR_NO_HARDWARE_CURSORS = "1";

    # Use Vulkan renderer for better performance
    WLR_RENDERER = "vulkan";

    # Set session type to Wayland
    XDG_SESSION_TYPE = "wayland";

    # Enable better Firefox/Mozilla input handling
    MOZ_USE_XINPUT2 = "1";

    # Use Adwaita dark theme for Qt applications
    QT_STYLE_OVERRIDE = "adwaita-dark";

    # Enable GTK portal integration
    GTK_USE_PORTAL = "1";

    # Set GSettings schema directory
    GSETTINGS_SCHEMA_DIR = "/run/current-system/sw/share/gsettings-schemas/";
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
