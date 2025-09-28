{ pkgs, ... }: {
  # Common home packages for Wayland desktop environments
  home.packages = with pkgs; [
    # Wallpaper and background management
    swww

    # Screenshot and clipboard utilities
    grim
    slurp
    wl-clipboard

    # Application launcher
    rofi
  ];
}

