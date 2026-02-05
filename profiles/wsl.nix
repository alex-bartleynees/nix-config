{ config, lib, pkgs, self, users, inputs, ... }:
lib.mkIf config.profiles.wsl {
  # Use base profile for core services
  profiles.base = true;

  # WSL-specific configuration
  system.isWsl = true;

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = true;
    wslConf.interop.enabled = true;
    wslConf.network.generateHosts = false;
    defaultUser = (builtins.head users).username;
    startMenuLaunchers = true;
    wslConf.boot.systemd = true;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = false;
  };

  # Enable wsl vpn kit - directory and files will be created by tmpfiles

  systemd.services.wsl-vpnkit = {
    enable = true;
    description = "wsl-vpnkit";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "idle";
      Restart = "always";
      RestartSec = 10;
      KillMode = "mixed";
      Environment = [
        "VMEXEC_PATH=/etc/wsl-vpnkit/wsl-vm"
        "GVPROXY_PATH=/etc/wsl-vpnkit/wsl-gvproxy.exe"
      ];
      ExecStart = "/etc/wsl-vpnkit/wsl-vpnkit";
    };
  };

  # Programs
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld;
  };

  # Qt theming for WSL
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # VSCode remote workaround
  systemd.user = {
    paths.vscode-remote-workaround = {
      wantedBy = [ "default.target" ];
      pathConfig.PathChanged = "%h/.vscode-server/bin";
    };
    services.vscode-remote-workaround.script = ''
      for i in ~/.vscode-server/bin/*; do
        if [ -e $i/node ]; then
          echo "Fixing vscode-server in $i..."
          ln -sf ${pkgs.nodejs_22}/bin/node $i/node
        fi
      done
    '';
  };

  # Enable GPG agent with pinentry
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses; # or pinentry-tty
    enableSSHSupport = true; # optional, but useful
  };

  # Install pass and credential helpers system-wide
  environment.systemPackages = with pkgs; [
    pass
    gnupg
    docker-credential-helpers

    adwaita-qt
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    adwaita-icon-theme
    openssl
    zlib
    stdenv.cc.cc.lib

    #Packages for vpn kit
    iproute2
    iptables
    iputils
    dnsutils
  ];

  # Ensure proper environment variables
  environment.variables = { GPG_TTY = "$(tty)"; };

  systemd.tmpfiles.rules = [
    # Create wsl-vpnkit directory and symlink files
    "d /etc/wsl-vpnkit 0755 root root -"
    "L+ /etc/wsl-vpnkit/wsl-vpnkit - - - - ${inputs.wsl-vpnkit}/app/wsl-vpnkit"
    "L+ /etc/wsl-vpnkit/wsl-vm - - - - ${inputs.wsl-vpnkit}/app/wsl-vm"
    "L+ /etc/wsl-vpnkit/wsl-gvproxy.exe - - - - ${inputs.wsl-vpnkit}/app/wsl-gvproxy.exe"
    # SSL certificates
    "L+ /etc/ssl/certs/mkcert-rootCA.pem - - - - /home/alexbn/.local/share/mkcert/rootCA.pem"
    "L+ /etc/ssl/certs/aspnet-fullchain.pem - - - - /mnt/c/Users/AlexanderNees/.aspnet/https/fullchain.pem"
  ];
}
