{ config, lib, pkgs, users, self, ... }:
let
  paths = import "${self}/paths.nix" self;
  mkHostVms =
    import "${paths.microvmsLib}/microvm-host-vms.nix" { inherit lib; };
  primaryUser = (builtins.head users).username;
in lib.mkIf config.profiles.media-server {
  # Inherit linux-desktop profile
  profiles.linux-desktop = true;

  environment.systemPackages = [ pkgs.wakeonlan ];

  # Gaming configuration for streaming clients
  gaming = {
    enable = false;
    moonlight.enable = true;
  };

  # Hardware support for GPU acceleration
  nvidia = {
    enable = true;
    prime.enable = false;
  };

  # RGB lighting support
  rgb = {
    enable = true;
    motherboard = "amd";
    profile = "default";
    turnOffOnBoot = true;
  };

  impermanence.enable = lib.mkForce false;

  snapshots.enable = lib.mkForce false;

  # Prevent the system from ever sleeping or suspending
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets."hybrid-sleep".enable = false;

  services.displayManager.autoLogin = {
    enable = true;
    user = primaryUser;
  };

  # Static IP configuration for media server
  networking = {
    interfaces.eno1.ipv4.addresses = [{
      address = "192.168.0.169";
      prefixLength = 24;
    }];
    defaultGateway = "192.168.0.1";
    nameservers = [ "192.168.0.1" "8.8.8.8" ];

    # Firewall configuration for Docker networking
    firewall = {
      enable = true;

      # Must be false, not "loose", for this host to work as a Tailscale exit
      # node. NixOS hooks nixos-fw-rpfilter into mangle PREROUTING and it ends
      # in an unconditional DROP, so it kills forwarded packets before FORWARD
      # ever runs. The rule uses `-m rpfilter --validmark`, which folds the
      # packet's fwmark into the reverse-path route lookup — and Tailscale's
      # policy rules send that lookup to routing table 52, where a 100.64/10
      # source arriving on tailscale0 doesn't resolve. --loose doesn't help.
      checkReversePath = false;

      extraCommands = ''
        # extraCommands re-runs on every rebuild/firewall restart and Docker
        # never repopulates DOCKER-USER for us, so without this flush each
        # activation appends another copy of everything below on top of the
        # last — and a terminal DROP added in only the newest copy would be
        # bypassed by every earlier copy's RETURN before it's ever reached.
        iptables -F DOCKER-USER 2>/dev/null || true

        # Allow established/related connections (needed for exit node)
        iptables -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # Allow agent-vm microvm subnet — DOCKER-USER is hit by ALL forwarded
        # traffic (not just containers), so without this the VM's internet
        # access silently drops here before NAT/masquerade ever sees it.
        iptables -A DOCKER-USER -s 10.0.1.0/24 -j ACCEPT

        # Allow traffic from home assistant docker container to host
        iptables -A INPUT -s 172.32.0.0/16 -p tcp --dport 8123 -j ACCEPT

        # Let containers initiate their own outbound connections (updates,
        # API calls, etc). Matching on ingress interface means this only ever
        # covers container -> elsewhere traffic: packets *to* a published
        # container port arrive on eno1/tailscale0, not a docker bridge, so
        # they still have to clear the rules below.
        iptables -A DOCKER-USER -i docker0 -j ACCEPT
        iptables -A DOCKER-USER -i br-+ -j ACCEPT

        # Allow local network HTTP/HTTPS (Traefik)
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p tcp --dport 443 -j ACCEPT
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p tcp --dport 80 -j ACCEPT

        # Allow DNS from local network (home devices need this!)
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p tcp --dport 53 -j ACCEPT
        iptables -A DOCKER-USER -s 192.168.0.0/24 -p udp --dport 53 -j ACCEPT

        # Allow localhost
        iptables -A DOCKER-USER -i lo -j ACCEPT

        # Allow the Tailscale network, unrestricted by port. Tailscale ACLs
        # (default-deny plus an explicit opt-in "full access" grant) are the
        # actual authorization boundary here, not this firewall: devices
        # granted full access legitimately reach container admin UIs (Sonarr,
        # Radarr, Prowlarr, etc.) directly by port, and exit-node relay
        # traffic for any peer using this host as an exit node also needs to
        # pass here unrestricted.
        iptables -A DOCKER-USER -s 100.64.0.0/10 -j ACCEPT

        # Default-deny: anything that isn't LAN, an authorized tailnet peer,
        # or container-initiated egress is dropped instead of falling through
        # to Docker's default-permissive forwarding for published ports —
        # this is what actually stops an arbitrary internet source (e.g. via
        # a future router port-forward) from reaching a published container.
        iptables -A DOCKER-USER -j DROP
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

  home-manager.users.${primaryUser} = {
    # Disable hypridle — media server must never lock, suspend, or hibernate
    hypridle.enable = lib.mkForce false;

    wayland.windowManager.hyprland.settings.windowrule =
      [ "fullscreen on, match:class ^(com.moonlight_stream.Moonlight)$" ];

    systemd.user.services.moonlight = {
      Unit = {
        Description = "Moonlight game streaming client";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.moonlight-qt}/bin/moonlight";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };

  # Technitium DNS server
  technitiumDns.enable = true;

  # Monitoring and telemetry
  monitoring = {
    enable = true;
    prometheus.enable = true;
    grafana.httpAddr = "100.89.61.64";
    grafana.openFirewall = true;
  };

  # MicroVM
  microvmHost = {
    enable = true;
    externalInterface = "eno1";
    vms = mkHostVms [ "agent-vm" ];
  };

  # Syncthing - sync the Obsidian vault with desktop and wsl
  sops.secrets = {
    "syncthing/media/key" = {
      owner = "alexbn";
      group = "users";
      mode = "0400";
    };
    "syncthing/media/cert" = {
      owner = "alexbn";
      group = "users";
      mode = "0400";
    };
    "syncthing/gui-password" = {
      owner = "alexbn";
      group = "users";
      mode = "0400";
    };
  };

  syncthing = {
    enable = true;
    user = "alexbn";
    group = "users";
    identity.keyFile = config.sops.secrets."syncthing/media/key".path;
    identity.certFile = config.sops.secrets."syncthing/media/cert".path;
    gui.passwordFile = config.sops.secrets."syncthing/gui-password".path;
    settings = {
      gui.user = "alexbn";
      devices = {
        desktop.id =
          "H5XLOT2-MRE2ZF7-5SM7FHW-Y56VK6Y-3H7B5LF-3DDYVZC-MP5R2GK-ZI4ZEQB";
        wsl.id =
          "ZMVBMAF-ECJRLYM-KBFUCH5-UN767I7-RSCOMVH-KHKDX7O-WEQ7FZX-EHIY5QC";
        android.id =
          "7YL7JYC-SPRWDET-MUI4UFO-FPUYPWQ-RNFBO4V-YDSOCAH-XVDAELW-IQOKGQJ";
      };
      folders."obsidian-vault" = {
        path = "/home/alexbn/projects/obsidian-vault";
        devices = [ "desktop" "wsl" "android" ];
      };
    };
  };
}
