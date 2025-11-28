{ pkgs, inputs, ... }: {
  imports = [
    ./common/wayland.nix
    ./common/wlroots.nix
    inputs.mango.nixosModules.mango
  ];

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

  qt = { enable = true; };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config = {
      mango = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
    xdgOpenUsePortal = true;
  };

  environment.sessionVariables = {
    XCURSOR_SIZE = "24";
    XCURSOR_THEME = "Adwaita";
    XDG_CURRENT_DESKTOP = "mango";
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
