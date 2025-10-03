{ ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  profiles.linux-laptop = true;

  system.stateVersion = "25.05";
}
