{ pkgs, inputs, ... }: {
  imports = [ ./common/wayland.nix inputs.niri.nixosModules.niri ];

  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  environment.systemPackages = with pkgs; [ xwayland-satellite-unstable uwsm ];

  programs.uwsm = {
    enable = true;
    waylandCompositors.niri = {
      binPath = "/run/current-system/sw/bin/niri";
      prettyName = "Niri";
      comment = "Niri compositor with UWSM";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ];
    config = {
      niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
    xdgOpenUsePortal = true;
  };

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
  };

  security.pam.services.hyprlock = { };

  displayManager = {
    enable = true;
    autoLogin = {
      enable = true;
      command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.niri-unstable}/bin/niri";
    };
  };

  system.nixos.tags = [ "niri" ];
}
