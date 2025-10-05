{ pkgs, inputs, ... }: {
  imports = [ ./common/wayland.nix inputs.niri.nixosModules.niri ];

  programs.niri.enable = true;
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  environment.systemPackages = with pkgs; [ xwayland-satellite-unstable ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
  };

  security.pam.services.hyprlock = { };

  displayManager = {
    enable = true;
    autoLogin = {
      enable = true;
      command = "${pkgs.niri-unstable}/bin/niri-session";
    };
  };

  system.nixos.tags = [ "niri" ];
}
