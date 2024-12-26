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
    direnv
  ];

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  programs.nm-applet = { enable = true; };

  programs.dconf.enable = true;

  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "adwaita-dark";
  };

}
