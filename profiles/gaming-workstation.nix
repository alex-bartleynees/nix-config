{ config, lib, ... }:
lib.mkIf config.profiles.gaming-workstation {
  # Inherit linux-desktop profile
  profiles.linux-desktop = true;

  # Gaming configuration
  gaming = {
    enable = true;
    streaming.enable = true;
    streaming.gpu = "nvidia"; # GPU to use for game streaming
    streaming.resolution = "2560x1440@164.96"; # Resolution for game streaming
    streaming.monitor = 1; # Monitor to use for game streaming
  };

  # Nvidia GPU support
  nvidia.enable = true;

  # RGB lighting support
  rgb = {
    enable = true;
    motherboard = "amd";
    profile = "default";
  };

  # ZSA keyboard support
  voyager.enable = true;

  # Disable wake-up for Logitech USB Receiver (C548)
  services.udev.extraRules = ''
    # Disable wake-up for Logitech USB Receiver (C548)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
  '';
}
