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

  impermanence.enable = lib.mkForce false;

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

    # Firewall configuration for Docker networking
    firewall = {
      enable = true;

      extraCommands = ''
        # Allow established/related connections (needed for exit node)
        iptables -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # Allow traffic from home assistant docker container to host
        iptables -A INPUT -s 172.32.0.0/16 -p tcp --dport 8123 -j ACCEPT

        # Allow local network HTTP/HTTPS (Traefik)
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p tcp --dport 443 -j ACCEPT
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p tcp --dport 80 -j ACCEPT

        # Allow DNS from local network (home devices need this!)
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p tcp --dport 53 -j ACCEPT
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p udp --dport 53 -j ACCEPT

        # Allow localhost
        iptables -A DOCKER-USER -i lo -j ACCEPT

        # Allow Tailscale network (VPS connects via this!)
        iptables -A DOCKER-USER -s 100.64.0.0/10 -j ACCEPT

        # CRITICAL: Return to Docker for further processing
        iptables -A DOCKER-USER -j RETURN
      '';
    };
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
    systemd.timeouts = {
      start = "60m"; # Increase timeout for large backups
      stop = "5m"; # More time to cleanup on stop
    };
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

  # Technitium DNS server
  technitiumDns.enable = true;
}
