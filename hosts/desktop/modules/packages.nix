{ config, pkgs, ... }: {
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    (vim_configurable.customize {
      name = "vim";
      vimrcConfig.customRC = ''
        	 	 source $VIMRUNTIME/defaults.vim
           		 
             		 set clipboard=unnamedplus
           		 '';
    })
    wget
    wl-clipboard
    wl-clipboard-x11
    git
    gnome-keyring
    libsecret
    xdg-desktop-portal
    xdg-desktop-portal-wlr
    xdg-desktop-portal-gtk
    fontconfig
    adwaita-qt
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    adwaita-icon-theme
    udiskie
    networkmanagerapplet
    blueman
    pulseaudio
    openrgb-with-all-plugins
    vulkan-tools
    vulkan-validation-layers
    vulkan-loader
  ];

  programs.thunar.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  programs.nm-applet = { enable = true; };

  programs.dconf.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    package = pkgs.steam.override {
      extraLibraries = pkgs: [ pkgs.xorg.libxcb ];
      extraPkgs = pkgs:
        with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
          gamemode
        ];
    };
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    remotePlay.openFirewall =
      true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall =
      true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall =
      true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "adwaita-dark";
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true; # Fixes the CAP_SYS_NICE warning
  };

  programs.xwayland.enable = true;

}
