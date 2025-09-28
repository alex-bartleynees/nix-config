{ config, theme, username, ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  gaming = {
    enable = true; # Enable gaming setup
    streaming.enable = true; # Enable game streaming with Sunshine
    streaming.gpu = "nvidia"; # GPU to use for game streaming
    streaming.resolution = "2560x1440@164.96"; # Resolution for game streaming
    streaming.monitor = 1; # Monitor to use for game streaming
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
  };

  docker = {
    enable = true; # Enable Docker support
  };

  stylixTheming = {
    enable = true;
    image = theme.wallpaper;
    base16Scheme = theme.base16Scheme;
  };

  sambaClient = { enable = true; };

  services.udev.extraRules = ''
    # Disable wake-up for Logitech USB Receiver (C548)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
  '';

  silentBoot.enable = true;

  zswap.enable = true;

  snapshots.enable = true;

  # Enable impermanence with BTRFS reset on boot
  impermanence = {
    enable = true;
    subvolumes = {
      "@" = { mountpoint = "/"; };
      "@home" = { mountpoint = "/home"; };
    };
    persistPaths = config.myUsers.${username}.persistPaths;
    resetSubvolumes = [ ]; # Reset all subvolumes except @snapshots
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
