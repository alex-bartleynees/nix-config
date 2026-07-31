{
  nixosConfig = { config, lib, pkgs, self, ... }:
    let
      paths = import "${self}/paths.nix" self;
      mkHostVms =
        import "${paths.microvmsLib}/microvm-host-vms.nix" { inherit lib; };
    in lib.mkIf config.profiles.gaming-workstation {
      # Inherit linux-desktop profile
      profiles.linux-desktop = true;

      # Gaming configuration
      gaming = {
        enable = true;
        streaming.enable = true;
        streaming.gpu =
          "amd"; # AMD iGPU drives monitors; NVENC can't import cross-GPU DMA-BUF
        streaming.resolution =
          "3840x2160@164.96"; # Resolution for game streaming
        streaming.monitor = 1; # Monitor to use for game streaming
      };

      # Nvidia GPU support with PRIME (AMD 9700X integrated + RTX 4070)
      nvidia = {
        enable = true;
        prime = {
          enable = true;
          mode =
            "offload"; # On-demand NVIDIA, powers down when idle to save power
          amdgpuBusId =
            "PCI:17:0:0"; # AMD Radeon Graphics (integrated with 9700X)
          nvidiaBusId = "PCI:1:0:0"; # NVIDIA RTX 4070
        };
      };

      # RGB lighting support
      rgb = {
        enable = true;
        motherboard = "amd";
        profile = "default";
        turnOffOnBoot = true;
      };

      # ZSA keyboard support
      voyager.enable = true;

      # Virtualization support
      virtualisation.enable = true;

      # MicroVM
      microvmHost = {
        enable = true;
        vms = mkHostVms [ "dev-vm" ];
      };

      # Monitoring and telemetry
      monitoring.enable = false;

      # Enable Wake-on-WLAN for WiFi (wlp7s0 / phy0)
      systemd.services.wowlan = {
        description = "Enable Wake on WLAN";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        script = ''
          ${pkgs.iw}/bin/iw phy phy0 wowlan enable magic-packet
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      # Disable wake-up for Logitech USB Receiver (C548)
      services.udev.extraRules = ''
        # Disable wake-up for Logitech USB Receiver (C548)
        SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
      '';

      # Syncthing - sync the Obsidian vault with the wsl and media hosts
      sops.secrets = {
        "syncthing/desktop/key" = {
          owner = "alexbn";
          group = "users";
          mode = "0400";
        };
        "syncthing/desktop/cert" = {
          owner = "alexbn";
          group = "users";
          mode = "0400";
        };
        "syncthing/gui-password" = {
          owner = "alexbn";
          group = "users";
          mode = "0400";
        };
      };

      syncthing = {
        enable = true;
        user = "alexbn";
        group = "users";
        identity.keyFile = config.sops.secrets."syncthing/desktop/key".path;
        identity.certFile = config.sops.secrets."syncthing/desktop/cert".path;
        gui.passwordFile = config.sops.secrets."syncthing/gui-password".path;
        settings = {
          gui.user = "alexbn";
          devices = {
            wsl.id =
              "ZMVBMAF-ECJRLYM-KBFUCH5-UN767I7-RSCOMVH-KHKDX7O-WEQ7FZX-EHIY5QC";
            media.id =
              "RQVTHCZ-YKZ5AE7-6RYLBJU-IOY3RTK-DNBO4Y3-5ECHJ3H-UTPF4O5-XDTRRQ2";
          };
          folders."obsidian-vault" = {
            path = "/home/alexbn/Documents/obsidian-vault";
            devices = [ "wsl" "media" ];
          };
        };
      };
    };

  homeConfig = { osConfig, lib, pkgs, ... }:
    let monitors = osConfig.myConfig.monitors;
    in let
      toKanshiOutput = m: {
        criteria = m.name;
        status = "enable";
      };
    in lib.mkIf osConfig.profiles.gaming-workstation {
      services.kanshi = {
        enable = true;
        settings = [
          {
            profile = {
              name = "coding";
              outputs = map toKanshiOutput monitors;
            };
          }
          {
            profile = {
              name = "gaming";
              outputs = map (m:
                toKanshiOutput m
                // lib.optionalAttrs (!m.primary) { status = "disable"; })
                monitors;
            };
          }
        ];
      };

      home.packages = with pkgs; [ discord ];
    };
}
