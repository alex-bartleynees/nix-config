{ config, lib, pkgs, ... }:
lib.mkIf config.profiles.gaming-workstation {
  # Inherit linux-desktop profile
  profiles.linux-desktop = true;

  # Gaming configuration
  gaming = {
    enable = true;
    streaming.enable = true;
    streaming.gpu =
      "amd"; # AMD iGPU drives monitors; NVENC can't import cross-GPU DMA-BUF
    streaming.resolution = "3840x2160@164.96"; # Resolution for game streaming
    streaming.monitor = 1; # Monitor to use for game streaming
  };

  # Nvidia GPU support with PRIME (AMD 9700X integrated + RTX 4070)
  nvidia = {
    enable = true;
    prime = {
      enable = true;
      mode = "offload"; # On-demand NVIDIA, powers down when idle to save power
      amdgpuBusId = "PCI:17:0:0"; # AMD Radeon Graphics (integrated with 9700X)
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

  # Monitoring and telemetry
  monitoring.enable = true;

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
}
