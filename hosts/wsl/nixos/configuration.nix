{ username, ... }: {
  # Use base profile for core services
  profiles.base = true;

  # WSL-specific configuration
  system.isWsl = true;
  system.stateVersion = "24.05";

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = true;
    wslConf.interop.enabled = true;
    wslConf.network.generateHosts = false;
    defaultUser = username;
    startMenuLaunchers = true;
    wslConf.boot.systemd = true;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = false;
  };

  systemd.tmpfiles.rules = [
    "L+ /etc/ssl/certs/mkcert-rootCA.pem - - - - /home/alexbn/.local/share/mkcert/rootCA.pem"
    "L+ /etc/ssl/certs/aspnet-fullchain.pem - - - - /mnt/c/Users/AlexanderNees/.aspnet/https/fullchain.pem"
  ];
}
