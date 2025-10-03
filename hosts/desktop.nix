{ ... }: {
  profiles.gaming-workstation = true;

  gaming = {
    streaming.gpu = "nvidia"; # GPU to use for game streaming
    streaming.resolution = "2560x1440@164.96"; # Resolution for game streaming
    streaming.monitor = 1; # Monitor to use for game streaming
  };

  services.udev.extraRules = ''
    # Disable wake-up for Logitech USB Receiver (C548)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", ATTR{power/wakeup}="disabled"
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
