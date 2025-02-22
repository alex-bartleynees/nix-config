{ config, pkgs, ... }: {

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

  programs.thunar.enable = true;

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

}

