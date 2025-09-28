{ pkgs, ... }: {
  # Common packages for Wayland desktop environments
  environment.systemPackages = with pkgs; [
    # Qt/GTK theming packages
    adwaita-qt
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    adwaita-icon-theme
  ];
}