{ config, pkgs, lib, ... }:
let cfg = config.sambaClient;
in {
  options.sambaClient.enable = lib.mkEnableOption "Enable Samba client support";
  config = lib.mkIf cfg.enable {
    # Enable CIFS/SMB support
    boot.supportedFilesystems = [ "cifs" ];

    # Install CIFS utilities
    environment.systemPackages = with pkgs; [ cifs-utils ];

    sops.templates."samba-credentials" = {
      content = ''
        username=${config.sops.placeholder."samba/username"}
        password=${config.sops.placeholder."samba/password"}
        domain=WORKGROUP
      '';
      owner = "root";
      group = "root";
      mode = "0600";
    };

    # Auto-mount Samba share
    fileSystems."/mnt/media" = {
      device = "//100.89.61.64/jellyfin-pool";
      fsType = "cifs";
      options = let
        automount_opts =
          "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

      in [
        "${automount_opts},credentials=${
          config.sops.templates."samba-credentials".path
        },uid=1000,gid=1000,file_mode=0664,dir_mode=0775,forceuid,forcegid,vers=3.0"
      ];
    };
  };
}
