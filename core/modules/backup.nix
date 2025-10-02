{ config, lib, pkgs, ... }:
let
  cfg = config.backup;

  backupScript = pkgs.writeShellApplication {
    name = "restic-backup";
    runtimeInputs = with pkgs; [ restic openssh coreutils nettools ];
    text = ''
      set -euo pipefail

      # Logging function
      log() {
          echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
      }

      log "Starting Restic backup with SOPS-managed secrets..."

      # Validate that required secrets are loaded from SOPS
      if [ ! -f "''${RESTIC_PASSWORD}" ]; then
          log "Error: RESTIC_PASSWORD file not found. Check sops secret '${cfg.secrets.passwordPath}'"
          exit 1
      fi

      # shellcheck disable=SC2153
      if [ ! -f "''${BACKUP_SERVER}" ]; then
          log "Error: BACKUP_SERVER file not found. Check sops secret '${cfg.secrets.serverPath}'"
          exit 1
      fi

      # Read secrets from files
      RESTIC_PASSWORD_VALUE="$(cat "''${RESTIC_PASSWORD}")"
      export RESTIC_PASSWORD="$RESTIC_PASSWORD_VALUE"
      backup_server="$(cat "''${BACKUP_SERVER}")"
      export RESTIC_REPOSITORY="${cfg.repository.type}:''${backup_server}:${cfg.repository.path}"

      log "Restic version: $(restic version)"
      log "Repository: ''${RESTIC_REPOSITORY}"

      # Configure SSH for backup user
      log "Configuring SSH for backup..."
      mkdir -p ~/.ssh
      chmod 700 ~/.ssh

      # Create SSH config to handle Tailscale connections
      cat > ~/.ssh/config << 'EOF'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    BatchMode yes
EOF
      chmod 600 ~/.ssh/config

      # Test SSH connection via Tailscale
      log "Testing SSH connection to backup server via Tailscale..."
      if timeout 30 ssh -o ConnectTimeout=10 "''${backup_server}" "echo 'SSH connection successful'" 2>/dev/null; then
          log "SSH connection test passed"
      else
          log "Warning: SSH connection test failed. Backup may fail."
      fi

      # Initialize Restic repository (ignore error if already exists)
      log "Initializing Restic repository..."
      if timeout 60 restic init 2>/dev/null; then
          log "Repository initialized successfully"
      else
          log "Repository may already exist or initialization failed (this is usually normal)"
      fi

      # Define backup paths from configuration
      backup_paths=(
        ${lib.concatMapStringsSep "\n        " (path: ''"${path}"'') cfg.paths}
      )

      # Define exclusion patterns from configuration
      exclude_patterns=(
        ${lib.concatMapStringsSep "\n        " (pattern: ''"${pattern}"'') cfg.excludePatterns}
      )

      # Build exclude arguments
      exclude_args=()
      for pattern in "''${exclude_patterns[@]}"; do
          exclude_args+=(--exclude="$pattern")
      done

      # Check which backup paths exist and warn about missing ones
      existing_paths=()
      for path in "''${backup_paths[@]}"; do
          if [ -e "$path" ]; then
              existing_paths+=("$path")
              log "Found backup path: $path"
          else
              log "Warning: Backup path does not exist: $path"
          fi
      done

      if [ ''${#existing_paths[@]} -eq 0 ]; then
          log "Error: No backup paths exist. Please check your configuration."
          exit 1
      fi

      # Backup data
      log "Starting backup of ''${#existing_paths[@]} directories..."
      log "Backup paths: ''${existing_paths[*]}"

      # Perform the backup
      if restic backup \
          --verbose \
          "''${exclude_args[@]}" \
          "''${existing_paths[@]}"; then
          log "Backup completed successfully"
      else
          log "Error: Backup failed"
          exit 1
      fi

      # Prune old backups
      log "Pruning old backups (keeping last ${toString cfg.retention.daily} daily, ${toString cfg.retention.weekly} weekly, ${toString cfg.retention.monthly} monthly)..."
      if restic forget \
          --keep-daily ${toString cfg.retention.daily} \
          --keep-weekly ${toString cfg.retention.weekly} \
          --keep-monthly ${toString cfg.retention.monthly} \
          --tag "$(cat /etc/hostname)" \
          --prune \
          --verbose; then
          log "Pruning completed successfully"
      else
          log "Warning: Pruning failed"
      fi

      # Optional: Check repository integrity (only on Sundays to save time)
      if [ "$(date +%u)" -eq 7 ] && [ "''${RESTIC_CHECK:-false}" = "true" ]; then
          log "Running weekly repository integrity check..."
          if restic check --verbose; then
              log "Repository check completed successfully"
          else
              log "Warning: Repository check failed"
          fi
      fi

      # Show repository stats
      log "Repository statistics:"
      restic stats --mode restore-size

      log "Backup script completed successfully!"
    '';
  };
in {
  options.backup = {
    enable = lib.mkEnableOption "backup system configuration";

    user = lib.mkOption {
      type = lib.types.str;
      default = "backup";
      description = "User to run backup as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "backup";
      description = "Group for backup user";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of paths to backup";
      example = [
        "/home/user/Documents"
        "/var/lib/docker/volumes"
      ];
    };

    excludePatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "**/.git"
        "**/cache/**"
        "**/tmp/**"
        "**/.cache/**"
        "**/node_modules/**"
        "**/.terraform/**"
        "**/target/**"
      ];
      description = "List of exclude patterns for backup";
    };

    secrets = {
      passwordPath = lib.mkOption {
        type = lib.types.str;
        default = "backup/restic-password";
        description = "SOPS secret path for restic password";
      };

      serverPath = lib.mkOption {
        type = lib.types.str;
        default = "backup/server-address";
        description = "SOPS secret path for backup server address";
      };
    };

    repository = {
      type = lib.mkOption {
        type = lib.types.enum [ "sftp" "s3" "b2" "azure" "gs" "swift" "rest" "rclone" ];
        default = "sftp";
        description = "Restic repository type";
      };

      path = lib.mkOption {
        type = lib.types.str;
        default = "/srv/restic-repo";
        description = "Repository path on the backup server";
      };
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "02:00";
      description = "Backup schedule (systemd timer format)";
    };

    retention = {
      daily = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Number of daily backups to keep";
      };

      weekly = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of weekly backups to keep";
      };

      monthly = lib.mkOption {
        type = lib.types.int;
        default = 6;
        description = "Number of monthly backups to keep";
      };
    };

    enableIntegrityCheck = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable weekly repository integrity check";
    };

    systemd = {
      resourceLimits = {
        memoryMax = lib.mkOption {
          type = lib.types.str;
          default = "2G";
          description = "Maximum memory usage for backup service";
        };

        cpuQuota = lib.mkOption {
          type = lib.types.str;
          default = "50%";
          description = "CPU quota for backup service";
        };
      };

      timeouts = {
        start = lib.mkOption {
          type = lib.types.str;
          default = "10m";
          description = "Timeout for backup service start";
        };

        stop = lib.mkOption {
          type = lib.types.str;
          default = "30s";
          description = "Timeout for backup service stop";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # SOPS secrets configuration for backup
    sops.secrets = {
      "${cfg.secrets.passwordPath}" = {
        owner = cfg.user;
        group = cfg.group;
        mode = "0400";
      };
      "${cfg.secrets.serverPath}" = {
        owner = cfg.user;
        group = cfg.group;
        mode = "0400";
      };
    };

    # Create backup user
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = [ "tailscale" ];
      shell = pkgs.shadow;
      home = "/var/lib/${cfg.user}";
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    # Ensure SSH directory exists for backup user
    system.activationScripts.backup-ssh = {
      text = ''
        # Create home directory if it doesn't exist
        if [ ! -d /var/lib/${cfg.user} ]; then
          mkdir -p /var/lib/${cfg.user}
          chown ${cfg.user}:${cfg.group} /var/lib/${cfg.user}
          chmod 755 /var/lib/${cfg.user}
        fi

        # Create SSH directory
        mkdir -p /var/lib/${cfg.user}/.ssh
        chown ${cfg.user}:${cfg.group} /var/lib/${cfg.user}/.ssh
        chmod 700 /var/lib/${cfg.user}/.ssh
      '';
      deps = [ "users" ];
    };

    # Create systemd service for backup
    systemd.services.restic-backup = {
      description = "Restic Backup Service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${backupScript}/bin/restic-backup";

        # Security hardening
        PrivateTmp = true;
        ProtectHome = "read-only";
        ProtectSystem = "strict";
        ReadWritePaths = [ "/var/lib/${cfg.user}" "/tmp" "/var/log" ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        NoNewPrivileges = true;

        # Timeout settings
        TimeoutStartSec = cfg.systemd.timeouts.start;
        TimeoutStopSec = cfg.systemd.timeouts.stop;

        # Resource limits
        MemoryMax = cfg.systemd.resourceLimits.memoryMax;
        CPUQuota = cfg.systemd.resourceLimits.cpuQuota;
      };

      # Environment variables
      environment = {
        # Enable repository check on Sundays
        RESTIC_CHECK = lib.boolToString cfg.enableIntegrityCheck;
        # Load secrets directly as environment variables
        RESTIC_PASSWORD = config.sops.secrets."${cfg.secrets.passwordPath}".path;
        BACKUP_SERVER = config.sops.secrets."${cfg.secrets.serverPath}".path;
      };
    };

    # Create systemd timer for scheduled backups
    systemd.timers.restic-backup = {
      description = "Run restic backup on schedule";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true; # Run missed backups on boot
        RandomizedDelaySec = "15m"; # Add some randomization
        AccuracySec = "1m";
      };
    };

    # Create a manual backup service for immediate runs
    systemd.services.restic-backup-now = {
      description = "Run Restic Backup Immediately";

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${backupScript}/bin/restic-backup";
      };

      # Same configuration as the regular backup
      environment = config.systemd.services.restic-backup.environment;
    };

    # Install required packages and create a restore script
    environment.systemPackages = with pkgs; [
      restic
      openssh
      (writeShellScriptBin "restic-restore" ''
        # Quick restore script
        # Usage: sudo -u ${cfg.user} restic-restore <snapshot-id> <target-path>

        if [ $# -ne 2 ]; then
            echo "Usage: $0 <snapshot-id> <target-path>"
            echo "List snapshots with: sudo -u ${cfg.user} restic snapshots"
            exit 1
        fi

        # Source the same secrets as the backup service
        restic_password_file="${config.sops.secrets."${cfg.secrets.passwordPath}".path}"
        backup_server_file="${config.sops.secrets."${cfg.secrets.serverPath}".path}"

        if [ ! -f "$restic_password_file" ] || [ ! -f "$backup_server_file" ]; then
            echo "Error: Secret files not found. Make sure backup service is configured."
            exit 1
        fi

        export RESTIC_PASSWORD="$(cat "$restic_password_file")"
        backup_server="$(cat "$backup_server_file")"
        export RESTIC_REPOSITORY="${cfg.repository.type}:''${backup_server}:${cfg.repository.path}"

        echo "Restoring snapshot $1 to $2..."
        ${pkgs.restic}/bin/restic restore "$1" --target "$2" --verbose
      '')
    ];
  };
}
