{ ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  profiles.linux-laptop = true;

  # ThinkPad-specific TLP settings
  tlpSettings = {
    profile = "thinkpad";
    cpu.maxFreqOnBat = 2400000; # 2.4GHz max on battery
  };

  system.stateVersion = "25.05";
}
