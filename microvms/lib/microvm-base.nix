{ hostName, ipAddress, tapId, mac, gateway ? "10.0.0.1"
, dns ? [ "1.1.1.1" "8.8.8.8" ], mem ? 4096, vcpu ? 4, extraShares ? [ ]
, extraVolumes ? [ ], sshHostKeysDir ? null, }:
{ lib, pkgs, ... }: {
  networking.hostName = hostName;

  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  programs.zsh.enable = true;
  profiles.base = true;
  services.openssh = {
    enable = true;
  } // lib.optionalAttrs (sshHostKeysDir != null) {
    # Use pre-generated keys shared from the host — stays stable across reboots
    hostKeys = [{
      path = "/etc/ssh/host-keys/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  # writableStoreOverlay is incompatible with store optimisation
  nix.optimise.automatic = lib.mkForce false;
  nix.settings.auto-optimise-store = lib.mkForce false;

  microvm = {
    hypervisor = "qemu";
    inherit mem vcpu;

    # Writable overlay over the shared /nix/.ro-store — required for the
    # nix daemon to work and for home-manager activation to succeed.
    writableStoreOverlay = "/nix/.rw-store";

    # /var volume — persists nix db, sops age key, service state across reboots
    volumes = [{
      image = "var.img";
      mountPoint = "/var";
      size = 40960;
      fsType = "ext4";
      autoCreate = true;
    }] ++ extraVolumes;

    interfaces = [{
      type = "tap";
      id = tapId;
      inherit mac;
    }];

    shares = [{
      proto = "virtiofs";
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }] ++ lib.optional (sshHostKeysDir != null) {
      proto = "virtiofs";
      tag = "ssh-host-keys";
      source = sshHostKeysDir;
      mountPoint = "/etc/ssh/host-keys";
    } ++ extraShares;
  };

  systemd.mounts = [{
    what = "store";
    where = "/nix/store";
    overrideStrategy = "asDropin";
    unitConfig.DefaultDependencies = false;
  }];

  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."20-lan" = {
      matchConfig.Type = "ether";
      networkConfig = {
        Address = [ "${ipAddress}/24" ];
        Gateway = gateway;
        DNS = dns;
        DHCP = "no";
      };
    };
    networks."19-docker" = {
      matchConfig.Name = "veth*";
      linkConfig.Unmanaged = true;
    };
  };
}
