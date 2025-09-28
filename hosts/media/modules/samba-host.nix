{ config, pkgs, users, ... }:

let
  sambaUser = (builtins.head users).username;
  shareName = "jellyfin-pool";
  mediaPath = "/mnt/jellyfin-pool";

in {
  # Note: Using existing regular user instead of creating system user
  # Note: Directory permissions handled by storage.nix MergerFS mount

  # Configure Samba service
  services.samba = {
    enable = true;
    package = pkgs.samba;

    # Note: Not using openFirewall = true since we handle firewall manually for Tailscale-only access

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Media Server";
        "security" = "user";
        "map to guest" = "never";

        # Security via hosts allow/deny instead of interface binding
        # (Interface binding doesn't work properly with Tailscale TUN interfaces)
        "hosts allow" = "100.64.0.0/10 127.0.0.1";
        "hosts deny" = "ALL";

        # Disable NetBIOS for Tailscale-only access
        "disable netbios" = "yes";
        "smb ports" = "445";

        # Performance optimizations for media
        "socket options" =
          "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
        "use sendfile" = "yes";

        # Logging
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "1000";
        "log level" = "0";
      };

      # Define the Jellyfin media share
      ${shareName} = {
        "path" = mediaPath;
        "comment" = "Jellyfin Media Pool";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = sambaUser;
        "force group" = "users";
      };
    };
  };

  # Ensure Samba starts after Tailscale and mount point exists
  systemd.services.samba-smbd = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    requisite = [ "mnt-jellyfin\\x2dpool.mount" ];

    # Wait for Tailscale interface before starting
    preStart = ''
      for i in {1..30}; do
        if ${pkgs.iproute2}/bin/ip link show | ${pkgs.gnugrep}/bin/grep -q tailscale; then
          echo "Tailscale interface found, starting Samba"
          exit 0
        fi
        echo "Waiting for Tailscale interface... ($i/30)"
        sleep 2
      done
      echo "Warning: Tailscale interface not found, starting anyway"
    '';
  };

  # Disable NetBIOS (nmbd) service since we're using Tailscale only
  systemd.services.samba-nmbd.enable = false;

  # Firewall configuration
  networking.firewall = {
    # Block SMB ports from all interfaces by default
    allowedTCPPorts = [ ];

    # Use extraCommands to allow Tailscale network access only
    extraCommands = ''
      # Allow SMB only from Tailscale network (100.64.0.0/10)
      iptables -I INPUT -p tcp -s 100.64.0.0/10 --dport 445 -j ACCEPT
      iptables -I INPUT -p tcp -s 127.0.0.1 --dport 445 -j ACCEPT
    '';

    extraStopCommands = ''
      # Clean up rules on stop
      iptables -D INPUT -p tcp -s 100.64.0.0/10 --dport 445 -j ACCEPT 2>/dev/null || true
      iptables -D INPUT -p tcp -s 127.0.0.1 --dport 445 -j ACCEPT 2>/dev/null || true
    '';
  };

  # Set up Samba user via systemd service instead of activation script
  systemd.services.setup-samba-user = {
    description = "Setup Samba User";
    wantedBy = [ "samba-smbd.service" ];
    before = [ "samba-smbd.service" ];
    after = [ "users.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Ensure Samba directories exist
      mkdir -p /var/lib/samba/private

      # Check if user exists in smbpasswd
      if ! ${pkgs.samba}/bin/pdbedit -L 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "^${sambaUser}:" 2>/dev/null; then
        echo "Adding ${sambaUser} to Samba users..."
        # Read password from sops secret file
        if [ -f "${config.sops.secrets."samba/password".path}" ]; then
          PASSWORD=$(cat ${config.sops.secrets."samba/password".path})
          echo -e "$PASSWORD\n$PASSWORD" | ${pkgs.samba}/bin/smbpasswd -a ${sambaUser}
        else
          echo "Warning: Samba password secret not found"
        fi
      fi

      # Ensure user is enabled
      ${pkgs.samba}/bin/smbpasswd -e ${sambaUser} 2>/dev/null || true
    '';
  };

  environment.systemPackages = with pkgs; [
    samba
    (writeScriptBin "samba-info" ''
      #!/bin/sh
      echo "Samba Media Server Information:"
      echo "=============================="
      echo "Share name: ${shareName}"
      echo "Path: ${mediaPath}"
      echo "User: ${sambaUser}"
      echo "Tailscale IP: $(${tailscale}/bin/tailscale ip -4 2>/dev/null || echo 'Run: tailscale ip -4')"
      echo "Windows: \\\\$(${tailscale}/bin/tailscale ip -4 2>/dev/null || echo 'TAILSCALE-IP')\\${shareName}"
      echo "Linux: smb://$(${tailscale}/bin/tailscale ip -4 2>/dev/null || echo 'TAILSCALE-IP')/${shareName}"
      echo "Security: SMB access restricted to Tailscale network (100.64.0.0/10)"
      echo ""
      echo "Test configuration with: ${samba}/bin/testparm -s"
    '')
  ];
}
