{ config, pkgs, lib, ... }:

let
  username = builtins.head
    (builtins.filter (user: config.users.users.${user}.isNormalUser)
      (builtins.attrNames config.users.users));
  sambaUser = "mediauser";
  shareName = "jellyfin-pool";
  mediaPath = "/mnt/jellyfin-pool";

in {
  sops.defaultSopsFile = ../../../secrets/samba.yaml;
  sops.age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

  sops.secrets.samba_password = { };

  # Create the media user
  users.users.${sambaUser} = {
    isSystemUser = true;
    group = sambaUser;
    shell = null;
  };
  users.groups.${sambaUser} = { };

  # Ensure media directory exists with proper permissions
  systemd.tmpfiles.rules =
    [ "d ${mediaPath} 0775 ${sambaUser} ${sambaUser} - -" ];

  # Configure Samba service
  services.samba = {
    enable = true;
    package = pkgs.samba;

    # Security settings

    # Global Samba configuration
    extraConfig = ''
      workgroup = WORKGROUP
      server string = Media Server
      security = user
      map to guest = never

      # Security via hosts allow/deny instead of interface binding
      # (Interface binding doesn't work properly with Tailscale TUN interfaces)
      hosts allow = 100.64.0.0/10 127.0.0.1
      hosts deny = ALL

      # Disable NetBIOS for Tailscale-only access
      disable netbios = yes
      smb ports = 445

      # Performance optimizations for media
      socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
      use sendfile = yes

      # Logging
      log file = /var/log/samba/log.%m
      max log size = 1000
      log level = 0
    '';

    # Define shares
    shares = {
      ${shareName} = {
        path = mediaPath;
        comment = "Jellyfin Media Pool";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "${sambaUser} ${username}";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = sambaUser;
        "force group" = sambaUser;
      };
    };
  };

  # Ensure Samba starts after Tailscale and mount point exists
  systemd.services.samba-smbd = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    requisite = [ "mnt-jellyfinx2dpool.mount" ];

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

  # Activation script to set up Samba user password using sops secret
  system.activationScripts.setupSambaUser = {
    text = ''
      # Check if user exists in smbpasswd
      if ! ${pkgs.samba}/bin/pdbedit -L | ${pkgs.gnugrep}/bin/grep -q "^${sambaUser}:"; then
        echo "Adding ${sambaUser} to Samba users..."
        # Read password from sops secret file
        PASSWORD=$(cat ${config.sops.secrets.samba_password.path})
        echo -e "$PASSWORD\n$PASSWORD" | ${pkgs.samba}/bin/smbpasswd -a ${sambaUser}
      fi

      # Ensure user is enabled
      ${pkgs.samba}/bin/smbpasswd -e ${sambaUser} 2>/dev/null || true
    '';
    deps = [ "users" "setupSecrets" ];
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

# USAGE INSTRUCTIONS:
# 1. Replace the variables at the top (sambaUser, sambaPassword, shareName, mediaPath)
# 2. For production use, replace the plain text password with a proper secret:
#    - Use agenix: https://github.com/ryantm/agenix
#    - Use sops-nix: https://github.com/Mic92/sops-nix
#    - Or NixOS's built-in secrets: config.age.secrets or similar
# 3. Add this configuration to your configuration.nix or import as a module
# 4. Run: sudo nixos-rebuild switch
# 5. Check status with: systemctl status samba-smbd
# 6. Get connection info with: samba-info
