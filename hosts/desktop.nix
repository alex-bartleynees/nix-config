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

}
