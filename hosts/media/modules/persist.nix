{ lib, ... }: {
  # Boot configuration with impermanence
  fileSystems."/persist".neededForBoot = true;
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/disk/by-label/nixos /btrfs_tmp
    if [[ -e /btrfs_tmp/@ ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/@ /btrfs_tmp/old_roots/$timestamp
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +7); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/@
    umount /btrfs_tmp
  '';

  # System persistence
  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/docker"
      "/var/lib/tailscale"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/etc/nixos"
    ];
    files = [ "/etc/machine-id" ];
    users.alexbn = {
      directories = [
        "Documents"
        ".config/moonlight"
        ".config/cosmic"
        ".config/dconf"
        ".cache/moonlight"
        ".config/atuin"
        ".gnupg"
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        {
          directory = ".config/sops";
          mode = "0700"; # Secure permissions
        }
        ".local/state/nvim"
        ".local/state/lazygit"
        ".local/share/direnv"
        ".local/share/zoxide"
        ".local/share/atuin"
      ];
    };
  };
}
