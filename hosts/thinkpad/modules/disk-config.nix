{
  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "luks";
                name = "crypted-swap";
                settings = { allowDiscards = true; };
                content = {
                  type = "swap";
                  discardPolicy = "both";
                  resumeDevice = true; # resume from hiberation from this device
                };
              };
            };
            # Btrfs Root Partition
            root = {
              size = "100%"; # Use remaining space
              content = {
                type = "luks";
                name = "crypted";
                settings = { allowDiscards = true; };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L" "nixos" ];
                  subvolumes = {
                    "@" = {
                      mountpoint = "/"; # Root subvolume
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]; # Compression for better performance
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix"; # Nix subvolume
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "noacl"
                      ]; # Optimize for Nix store
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
