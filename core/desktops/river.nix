{ pkgs, ... }: {
  imports = [
    ../wayland.nix
    ../wayland-packages.nix
    ../wayland-system.nix
    ../wlroots.nix
  ];
  environment.systemPackages = with pkgs; [
    river-classic
  ];

  programs.river-classic = { enable = true; };

  programs.uwsm = {
    enable = true;
    waylandCompositors.river = {
      binPath = "/run/current-system/sw/bin/river";
      prettyName = "River";
      comment = "River compositor with UWSM";
    };
  };

  qt = { enable = true; };

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "river";
    XDG_SESSION_DESKTOP = "river";
    #GTK_THEME = "Adwaita:dark";
    # Force dark mode for websites
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config.common.default = [ "wlr" ];
    xdgOpenUsePortal = true;
  };

  security.pam.services.hyprlock = { };

  displayManager = {
    enable = true;
    autoLogin = {
      enable = true;
      command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.river-classic}/bin/river";
    };
  };

  system.nixos.tags = [ "river" ];

}

