{ pkgs, ... }: {
  imports = [ ./common/wayland.nix ];
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

  environment.systemPackages = with pkgs; [ hyprutils ];

  security.pam.services.hyprlock = { };

  displayManager = {
    enable = true;
    autoLogin = { enable = true; };
  };

  system.nixos.tags = [ "hyprland" ];
}
