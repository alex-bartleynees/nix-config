{ config, lib, ... }:
lib.mkIf config.profiles.media-server {
  # Inherit linux-desktop profile
  profiles.linux-desktop = true;

  # Gaming configuration for streaming clients
  gaming = {
    enable = false;
    moonlight.enable = true;
  };

  # Hardware support for GPU acceleration
  nvidia.enable = true;

  # RGB lighting support
  rgb = {
    enable = true;
    motherboard = "amd";
    profile = "default";
  };

  # Enable impermanence only for root filesystem
  impermanence = {
    enable = true;
    resetSubvolumes = [ "@" ]; # Only reset root subvolume, preserve @home
    subvolumes = {
      "@" = { mountpoint = "/"; };
      "@home" = { mountpoint = "/home"; };
    };
  };

  # Media server specific configurations
  services.displayManager.gdm.enable = lib.mkForce false;

  # Enhanced Tailscale for routing
  tailscale.routingFeatures = "both";

  sambaClient.enable = lib.mkForce false;
}
