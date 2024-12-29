{ config, lib, pkgs, ... }: {
  networking.hostName = "nixos";
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;

  services.dbus = {
    enable = true;
    implementation = "broker";
  };

  security.pam.services.login.enableWsl = true;

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
    fontconfig
    adwaita-qt
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    adwaita-icon-theme
  ];

  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "adwaita-dark";
  };

  systemd.user = {
    paths.vscode-remote-workaround = {
      wantedBy = [ "default.target" ];
      pathConfig.PathChanged = "%h/.vscode-server/bin";
    };
    services.vscode-remote-workaround.script = ''
      for i in ~/.vscode-server/bin/*; do
        if [ -e $i/node ]; then
          echo "Fixing vscode-server in $i..."
          ln -sf ${pkgs.nodejs_18}/bin/node $i/node
        fi
      done
    '';
  };

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
    defaultUser = "alexbn";
    startMenuLaunchers = true;
    nativeSystemd = true;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = false;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  system.stateVersion = "24.05";
}
