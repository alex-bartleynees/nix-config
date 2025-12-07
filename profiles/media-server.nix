{ config, lib, pkgs, ... }:
lib.mkIf config.profiles.media-server {
  # Inherit linux-desktop profile
  profiles.linux-desktop = true;

  # Gaming configuration for streaming clients
  gaming = {
    enable = false;
    moonlight.enable = true;
  };

  # Hardware support for GPU acceleration
  nvidia.enable = true;

  # RGB lighting support
  rgb = {
    enable = true;
    motherboard = "amd";
    profile = "default";
  };

  # Enable impermanence only for root filesystem
  impermanence = {
    enable = true;
    resetSubvolumes = [ "@" ]; # Only reset root subvolume, preserve @home
    subvolumes = {
      "@" = { mountpoint = "/"; };
      "@home" = { mountpoint = "/home"; };
    };
  };

  # Media server specific configurations
  services.displayManager.gdm.enable = lib.mkForce false;

  # Static IP configuration for media server
  networking = {
    interfaces.enp4s0.ipv4.addresses = [{
      address = "192.168.0.169";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.0.1";
    nameservers = [ "192.168.0.1" "8.8.8.8" ];

    # Allow traffic from home assistant docker container to host
    firewall.extraCommands = ''
      iptables -A INPUT -s 172.32.0.0/16 -p tcp --dport 8123 -j ACCEPT
    '';
  };

  # Enhanced Tailscale for routing
  tailscale = {
    routingFeatures = "server";
    configureUdpGro = true;
  };

  sambaClient.enable = lib.mkForce false;

  # Backup configuration
  backup = {
    enable = true;
    paths = [
      # User homelab directory
      "/home/alexbn/Documents/homelab"

      # Media directories
      "/mnt/jellyfin-pool/books"
      "/mnt/jellyfin-pool/documents"
      "/mnt/jellyfin-pool/photos"

      # Docker volumes
      "/var/lib/docker/volumes"
    ];
    excludePatterns = [
      "/home/*/homelab/jellyfin-docker/cache"
      "**/.git"
      "**/cache/**"
      "**/tmp/**"
      "**/.cache/**"
      "**/node_modules/**"
      "**/target/**"
    ];
  };

  # Samba host configuration
  sambaHost = {
    enable = true;
    serverString = "Media Server";
    shares = {
      jellyfin-pool = {
        path = "/mnt/jellyfin-pool";
        comment = "Jellyfin Media Pool";
        browseable = true;
        readOnly = false;
        guestOk = false;
        createMask = "0664";
        directoryMask = "0775";
        forceGroup = "users";
      };
    };
    systemd = { mountRequirements = [ "mnt-jellyfin\\x2dpool.mount" ]; };
  };

  # Cage kiosk configuration
  cage = {
    enable = true;
    application = "${pkgs.moonlight-qt}/bin/moonlight";
    cageArgs = [ "-s" ];
  };
}
