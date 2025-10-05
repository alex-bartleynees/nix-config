{ pkgs, inputs, ... }:
let
  mango = inputs.mango.packages.${pkgs.system}.mango;
in {
  imports = [ ./common/wayland.nix ./common/wlroots.nix inputs.mango.nixosModules.mango ];

  programs.mango.enable = true;

  programs.uwsm = {
    enable = true;
    waylandCompositors.mango = {
      binPath = "/run/current-system/sw/bin/mango";
      prettyName = "Mango";
      comment = "Mango compositor with UWSM";
    };
  };

  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config.common.default = [ "wlr" ];
    xdgOpenUsePortal = true;
  };

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "wlroots";
    XDG_SESSION_DESKTOP = "mango";
  };

  security.pam.services.hyprlock = { };

  displayManager = {
    enable = true;
    autoLogin = {
      enable = true;
      command = "${pkgs.uwsm}/bin/uwsm start /run/current-system/sw/bin/mango";
    };
  };

  system.nixos.tags = [ "mangowc" ];
}
