{ pkgs, ... }: {
  # Packages specific to wlroots-based desktop environments (Sway, River, etc.)
  environment.systemPackages = with pkgs; [
    # wlroots-specific XDG portal
    xdg-desktop-portal-wlr

    # Universal Wayland Session Manager (wlroots compositors)
    uwsm
  ];
}