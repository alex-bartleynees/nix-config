{ pkgs, ... }: {
  imports = [
    ../wayland.nix
    ../wayland-packages.nix
    ../wayland-system.nix
  ];
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };


  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  security.pam.services.hyprlock = { };

  displayManager = {
    enable = true;
    autoLogin = { enable = true; };
  };

  system.nixos.tags = [ "hyprland" ];
}
