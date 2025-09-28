{ username, ... }: {
  system.isWsl = true;
  # System identification
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

  # Docker support
  docker.enable = true;

  tailscale.enable = true;

  systemd.tmpfiles.rules = [
    "L+ /etc/ssl/certs/mkcert-rootCA.pem - - - - /home/alexbn/.local/share/mkcert/rootCA.pem"
    "L+ /etc/ssl/certs/aspnet-fullchain.pem - - - - /mnt/c/Users/AlexanderNees/.aspnet/https/fullchain.pem"
  ];
}
