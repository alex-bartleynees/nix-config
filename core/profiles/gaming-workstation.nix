{ config, lib, ... }:
lib.mkIf config.profiles.gaming-workstation {
  # Inherit linux-desktop profile
  profiles.linux-desktop = true;

  # Gaming configuration
  gaming = {
    enable = true;
    streaming.enable = true;
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
}
