{ config, lib, pkgs, inputs, ... }:
let shared = import ../../../shared/nixos-default.nix { inherit inputs; };
in {
  imports =
    shared.getImports { additionalImports = [ ../modules/regreet.nix ]; };

  environment.systemPackages = with pkgs; [
    gnome-keyring
    libsecret
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    adwaita-qt
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    adwaita-icon-theme
    udiskie
    networkmanagerapplet
    blueman
    pulseaudio
  ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export ZDOTDIR=''${HOME}
      export SHELL=${pkgs.zsh}/bin/zsh
      source "''${HOME}/.zshenv"
      ZSH_DISABLE_COMPFIX=true
      DISABLE_AUTO_UPDATE=true
    '';

    extraOptions = [ "--unsupported-gpu" ];
  };

  qt = {
    enable = true;
    #platformTheme = "gtk2";
    #style = "adwaita-dark";
  };

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_RENDERER = "vulkan";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    #GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
    MOZ_USE_XINPUT2 = "1";
    # Force dark mode for websites
    GTK_USE_PORTAL = "1";
    GSETTINGS_SCHEMA_DIR = "/run/current-system/sw/share/gsettings-schemas/";
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
    config.common.default = [ "wlr" ];
    xdgOpenUsePortal = true;
  };

  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.swaylock = { text = "auth include login"; };
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Enable networking
  networking.networkmanager.enable = true;

  system.nixos.tags = [ "sway" ];
}
