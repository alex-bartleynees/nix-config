{ config, lib, pkgs, self, users, ... }:
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
  ];

  # Ensure proper environment variables
  environment.variables = { GPG_TTY = "$(tty)"; };

  systemd.tmpfiles.rules = [
    "L+ /etc/ssl/certs/mkcert-rootCA.pem - - - - /home/alexbn/.local/share/mkcert/rootCA.pem"
    "L+ /etc/ssl/certs/aspnet-fullchain.pem - - - - /mnt/c/Users/AlexanderNees/.aspnet/https/fullchain.pem"
  ];
}
