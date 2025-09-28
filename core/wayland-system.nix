{ pkgs, ... }: {
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
  ];
}