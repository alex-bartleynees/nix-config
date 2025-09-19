{ pkgs, ... }: {
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
    uwsm
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

  # Enable uwsm for sway session management
  programs.uwsm = {
    enable = true;
    waylandCompositors.sway = {
      binPath = "/run/current-system/sw/bin/sway";
      prettyName = "Sway";
      comment = "Sway compositor with UWSM";
    };
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
    WLR_RENDERER = "vulkan";
    XDG_SESSION_TYPE = "wayland";
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

  security.pam.services.swaylock = { text = "auth include login"; };

  displayManager = { enable = true; };

  system.nixos.tags = [ "sway" ];
}
