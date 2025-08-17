{ config, pkgs, ... }:

let
  username = builtins.head
    (builtins.filter (user: config.users.users.${user}.isNormalUser)
      (builtins.attrNames config.users.users));

  backupScript = pkgs.writeShellApplication {
    name = "restic-backup";
    runtimeInputs = with pkgs; [ restic openssh coreutils ];
    text = ''
      set -euo pipefail

      # Logging function
      log() {
          echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
      }

      log "Starting Restic backup with SOPS-managed secrets..."

      # Validate that required secrets are loaded from SOPS
      if [ ! -f "''${RESTIC_PASSWORD}" ]; then
          log "Error: RESTIC_PASSWORD file not found. Check sops secret 'backup/restic-password'"
          exit 1
      fi

      if [ ! -f "''${BACKUP_SERVER}" ]; then
          log "Error: BACKUP_SERVER file not found. Check sops secret 'backup/server-address'"
          exit 1
      fi

      # Read secrets from files
      export RESTIC_PASSWORD="$(cat "''${RESTIC_PASSWORD}")"
      backup_server="$(cat "''${BACKUP_SERVER}")"
      # Build repository URL from the secret
      export RESTIC_REPOSITORY="sftp:''${backup_server}:/srv/restic-repo"

      log "Restic version: $(restic version)"
      log "Repository: ''${RESTIC_REPOSITORY}"

      # Test SSH connection
      log "Testing SSH connection to backup server..."
      if timeout 30 ssh -o ConnectTimeout=10 -o BatchMode=yes "''${backup_server}" "echo 'SSH connection successful'" 2>/dev/null; then
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

      # Define backup paths - adjust these for your setup
      backup_paths=(
          # User homelab directory
          "/home/alexbn/homelab"

          # Media directories (adjust paths as needed)
          "/mnt/jellyfin-pool/books"
          "/mnt/jellyfin-pool/documents"
          "/mnt/jellyfin-pool/photos"
          "/mnt/jellyfin-pool/seafile"
          
          # Docker volumes
          "/var/lib/docker/volumes"
      )

      # Define exclusion patterns
      exclude_patterns=(
          "/home/*/homelab/jellyfin-docker/cache"
          "**/.git"
          "**/cache/**"
          "**/tmp/**"
          "**/.cache/**"
          "**/node_modules/**"
          "**/.terraform/**"
          "**/target/**"
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
          --one-file-system \
          --tag "$(hostname)" \
          --tag "$(date '+%Y-%m')" \
          "''${exclude_args[@]}" \
          "''${existing_paths[@]}"; then
          log "Backup completed successfully"
      else
          log "Error: Backup failed"
          exit 1
      fi

      # Prune old backups
      log "Pruning old backups (keeping last 7 daily, 4 weekly, 6 monthly)..."
      if restic forget \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6 \
          --tag "$(hostname)" \
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
  # SOPS configuration
  sops.defaultSopsFile = ../../../secrets/backup.yaml;
  sops.age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

  # SOPS secrets configuration for backup
  sops.secrets = {
    "backup/restic-password" = {
      owner = "backup";
      group = "backup";
      mode = "0400";
    };
    "backup/server-address" = {
      owner = "backup";
      group = "backup";
      mode = "0400";
    };
  };

  # Create backup user
  users.users.backup = {
    isSystemUser = true;
    group = "backup";
    home = "/var/lib/backup";
    createHome = true;
    shell = pkgs.bash;
  };

  users.groups.backup = { };

  # Ensure SSH directory exists for backup user
  system.activationScripts.backup-ssh = {
    text = ''
      mkdir -p /var/lib/backup/.ssh
      chown backup:backup /var/lib/backup/.ssh
      chmod 700 /var/lib/backup/.ssh
    '';
  };

  # Create systemd service for backup
  systemd.services.restic-backup = {
    description = "Restic Backup Service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "backup";
      Group = "backup";
      ExecStart = "${backupScript}/bin/restic-backup";

      # Security hardening
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/backup" "/tmp" "/var/log" ];
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      NoNewPrivileges = true;

      # Timeout settings
      TimeoutStartSec = "10m";
      TimeoutStopSec = "30s";

      # Resource limits
      MemoryMax = "2G";
      CPUQuota = "50%";
    };

    # Environment variables (non-secret)
    environment = {
      # Enable repository check on Sundays
      RESTIC_CHECK = "true";
      # Load secrets directly as environment variables
      RESTIC_PASSWORD = config.sops.secrets."backup/restic-password".path;
      BACKUP_SERVER = config.sops.secrets."backup/server-address".path;
    };
  };

  # Create systemd timer for daily backups at 2 AM
  systemd.timers.restic-backup = {
    description = "Run restic backup daily";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "02:00";
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
      User = "backup";
      Group = "backup";
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
      # Usage: sudo -u backup restic-restore <snapshot-id> <target-path>

      if [ $# -ne 2 ]; then
          echo "Usage: $0 <snapshot-id> <target-path>"
          echo "List snapshots with: sudo -u backup restic snapshots"
          exit 1
      fi

      # Source the same secrets as the backup service
      restic_password_file="${
        config.sops.secrets."backup/restic-password".path
      }"
      backup_server_file="${config.sops.secrets."backup/server-address".path}"

      if [ ! -f "$restic_password_file" ] || [ ! -f "$backup_server_file" ]; then
          echo "Error: Secret files not found. Make sure backup service is configured."
          exit 1
      fi

      export RESTIC_PASSWORD="$(cat "$restic_password_file")"
      backup_server="$(cat "$backup_server_file")"
      export RESTIC_REPOSITORY="sftp:''${backup_server}:/srv/restic-repo"

      echo "Restoring snapshot $1 to $2..."
      ${pkgs.restic}/bin/restic restore "$1" --target "$2" --verbose
    '')
  ];
}
