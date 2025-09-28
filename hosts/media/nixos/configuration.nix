{ pkgs, lib, ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  gaming = {
    enable = false;
    moonlight.enable = true; # Enable Moonlight for game streaming
  };

  nvidia = {
    enable = true; # Enable NVIDIA GPU support
  };

  rgb = {
    enable = true; # Enable OpenRGB support
    motherboard = "amd"; # Motherboard type for OpenRGB
    profile = "default"; # OpenRGB profile to use on startup
  };

  tailscale = {
    enable = true; # Enable Tailscale support
    routingFeatures = "both";
  };

  docker = {
    enable = true; # Enable Docker support
  };

  stylixTheming = { enable = true; };

  qt = {
    enable = true;
    platformTheme = lib.mkForce "gnome";
    style = "adwaita-dark";
  };


  services.displayManager.gdm.enable = lib.mkForce false;
  zswap.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
