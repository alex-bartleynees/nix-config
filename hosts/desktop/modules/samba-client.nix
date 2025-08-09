{ config, pkgs, ... }:
let
  username = builtins.head
    (builtins.filter (user: config.users.users.${user}.isNormalUser)
      (builtins.attrNames config.users.users));
in {
  # Enable CIFS/SMB support
  boot.supportedFilesystems = [ "cifs" ];

  # Install CIFS utilities
  environment.systemPackages = with pkgs; [ cifs-utils ];

  sops.defaultSopsFile = ../../../secrets/samba.yaml;
  sops.age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

  sops.secrets.samba_username = { };
  sops.secrets.samba_password = { };

  sops.templates."samba-credentials" = {
    content = ''
      username=${config.sops.placeholder.samba_username}
      password=${config.sops.placeholder.samba_password}
      domain=WORKGROUP
    '';
    owner = "root";
    group = "root";
    mode = "0600";
  };

  # Auto-mount Samba share
  fileSystems."/mnt/media" = {
    device = "//100.98.211.116/jellyfin-pool";
    fsType = "cifs";
    options = let
      automount_opts =
        "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in [
      "${automount_opts},credentials=${
        config.sops.templates."samba-credentials".path
      },uid=1000,gid=1000,file_mode=0664,dir_mode=0775,forceuid,forcegid"
    ];
  };
}
