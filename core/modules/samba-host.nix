{ config, lib, pkgs, users, ... }:
let cfg = config.sambaHost;
in {
  options.sambaHost = {
    enable = lib.mkEnableOption "Samba server configuration";

    user = lib.mkOption {
      type = lib.types.str;
      default = (builtins.head users).username;
      description = "Username for Samba authentication";
    };

    workgroup = lib.mkOption {
      type = lib.types.str;
      default = "WORKGROUP";
      description = "Samba workgroup name";
    };

    serverString = lib.mkOption {
      type = lib.types.str;
      default = "Samba Server";
      description = "Server description string";
    };

    allowedHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "100.64.0.0/10" "127.0.0.1" ];
      description = "List of allowed IP addresses/networks";
    };

    shares = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Path to share";
          };

          comment = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Share description";
          };

          browseable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether the share is browseable";
          };

          readOnly = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether the share is read-only";
          };

          guestOk = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Allow guest access";
          };

          createMask = lib.mkOption {
            type = lib.types.str;
            default = "0664";
            description = "File creation mask";
          };

          directoryMask = lib.mkOption {
            type = lib.types.str;
            default = "0775";
            description = "Directory creation mask";
          };

          forceUser = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Force user for file operations";
          };

          forceGroup = lib.mkOption {
            type = lib.types.str;
            default = "users";
            description = "Force group for file operations";
          };

          extraConfig = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Additional share configuration";
          };
        };
      });
      default = { };
      description = "Samba shares configuration";
      example = lib.literalExpression ''
        {
          media = {
            path = "/mnt/media";
            comment = "Media Files";
            browseable = true;
            readOnly = false;
          };
        }
      '';
    };

    security = {
      tailscaleOnly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Restrict access to Tailscale network only";
      };

      disableNetbios = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Disable NetBIOS for security";
      };

      smbPortsOnly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use SMB ports only (disable NetBIOS ports)";
      };
    };

    performance = {
      socketOptions = lib.mkOption {
        type = lib.types.str;
        default =
          "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
        description = "Socket options for performance";
      };

      useSendfile = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use sendfile for better performance";
      };
    };

    logging = {
      logFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/log/samba/log.%m";
        description = "Log file path";
      };

      maxLogSize = lib.mkOption {
        type = lib.types.int;
        default = 1000;
        description = "Maximum log size in KB";
      };

      logLevel = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Log level (0-10)";
      };
    };

    secrets = {
      passwordPath = lib.mkOption {
        type = lib.types.str;
        default = "samba/password";
        description = "SOPS secret path for Samba password";
      };
    };

    systemd = {
      dependencies = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional systemd service dependencies";
      };

      mountRequirements = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Required mount points before starting Samba";
      };

      waitForTailscale = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Wait for Tailscale interface before starting";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # SOPS secret for Samba password
    sops.secrets."${cfg.secrets.passwordPath}" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };

    # Configure Samba service
    services.samba = {
      enable = true;
      package = pkgs.samba;

      settings = {
        global = {
          "workgroup" = cfg.workgroup;
          "server string" = cfg.serverString;
          "security" = "user";
          "map to guest" = "never";

          # Security via hosts allow/deny
          "hosts allow" = lib.concatStringsSep " " cfg.allowedHosts;
          "hosts deny" = "ALL";

          # NetBIOS configuration
          "disable netbios" = lib.boolToString cfg.security.disableNetbios;
          "smb ports" = lib.mkIf cfg.security.smbPortsOnly "445";

          # Performance optimizations
          "socket options" = cfg.performance.socketOptions;
          "use sendfile" = lib.boolToString cfg.performance.useSendfile;

          # Logging
          "log file" = cfg.logging.logFile;
          "max log size" = toString cfg.logging.maxLogSize;
          "log level" = toString cfg.logging.logLevel;
        };
      } // lib.mapAttrs (shareName: shareConfig:
        {
          "path" = shareConfig.path;
          "comment" = shareConfig.comment;
          "browseable" = lib.boolToString shareConfig.browseable;
          "read only" = lib.boolToString shareConfig.readOnly;
          "guest ok" = lib.boolToString shareConfig.guestOk;
          "create mask" = shareConfig.createMask;
          "directory mask" = shareConfig.directoryMask;
          "force user" = if shareConfig.forceUser != null then shareConfig.forceUser else cfg.user;
          "force group" = shareConfig.forceGroup;
        } // shareConfig.extraConfig) cfg.shares;
    };

    # Systemd service configuration
    systemd.services.samba-smbd = {
      after = [ "tailscaled.service" ] ++ cfg.systemd.dependencies;
      wants = [ "tailscaled.service" ] ++ cfg.systemd.dependencies;
      requisite = cfg.systemd.mountRequirements;

      preStart = lib.mkIf cfg.systemd.waitForTailscale ''
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

    # Disable NetBIOS service if configured
    systemd.services.samba-nmbd.enable = !cfg.security.disableNetbios;

    # Firewall configuration for Tailscale-only access
    networking.firewall = lib.mkIf cfg.security.tailscaleOnly {
      allowedTCPPorts = [ ];

      extraCommands = ''
        # Allow SMB only from configured hosts
        ${lib.concatMapStringsSep "\n"
        (host: "iptables -I INPUT -p tcp -s ${host} --dport 445 -j ACCEPT")
        cfg.allowedHosts}
      '';

      extraStopCommands = ''
        # Clean up rules on stop
        ${lib.concatMapStringsSep "\n" (host:
          "iptables -D INPUT -p tcp -s ${host} --dport 445 -j ACCEPT 2>/dev/null || true")
        cfg.allowedHosts}
      '';
    };

    # Set up Samba user
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
        if ! ${pkgs.samba}/bin/pdbedit -L 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "^${cfg.user}:" 2>/dev/null; then
          echo "Adding ${cfg.user} to Samba users..."
          # Read password from sops secret file
          if [ -f "${
            config.sops.secrets."${cfg.secrets.passwordPath}".path
          }" ]; then
            PASSWORD=$(cat ${
              config.sops.secrets."${cfg.secrets.passwordPath}".path
            })
            echo -e "$PASSWORD\n$PASSWORD" | ${pkgs.samba}/bin/smbpasswd -a ${cfg.user}
          else
            echo "Warning: Samba password secret not found"
          fi
        fi

        # Ensure user is enabled
        ${pkgs.samba}/bin/smbpasswd -e ${cfg.user} 2>/dev/null || true
      '';
    };

    # System packages
    environment.systemPackages = with pkgs; [
      samba
      (writeScriptBin "samba-info" ''
        #!/bin/sh
        echo "Samba Server Information:"
        echo "========================"
        echo "Workgroup: ${cfg.workgroup}"
        echo "Server: ${cfg.serverString}"
        echo "User: ${cfg.user}"
        echo "Tailscale IP: $(${tailscale}/bin/tailscale ip -4 2>/dev/null || echo 'Run: tailscale ip -4')"
        echo ""
        echo "Shares:"
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (shareName: shareConfig: ''
          echo "  ${shareName}: ${shareConfig.path}"
          echo "    Comment: ${shareConfig.comment}"
          echo "    Windows: \\\\$(${tailscale}/bin/tailscale ip -4 2>/dev/null || echo 'TAILSCALE-IP')\\${shareName}"
          echo "    Linux: smb://$(${tailscale}/bin/tailscale ip -4 2>/dev/null || echo 'TAILSCALE-IP')/${shareName}"
        '') cfg.shares)}
        echo ""
        echo "Security: SMB access restricted to: ${
          lib.concatStringsSep ", " cfg.allowedHosts
        }"
        echo ""
        echo "Test configuration with: ${samba}/bin/testparm -s"
      '')
    ];
  };
}
