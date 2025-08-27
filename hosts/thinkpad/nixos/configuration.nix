{ config, pkgs, background, ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Networking
  networking.hostName = "thinkpad";

  tailscale = {
    enable = true; # Enable Tailscale support
  };

  docker = {
    enable = true; # Enable Docker support
  };

  stylixTheming = {
    enable = true;
    image = background.wallpaper;
  };

  silentBoot.enable = true;

  zswap.enable = true;

  # Lid close
  services.logind.lidSwitch = "suspend-then-hibernate";
  services.logind.lidSwitchExternalPower = "lock";
  services.logind.lidSwitchDocked = "ignore";

  # Define time delay for hibernation
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # Power button
  services.logind.powerKey = "hibernate";
  services.logind.powerKeyLongPress = "poweroff";

  # Power Management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  services.power-profiles-daemon.enable = true;
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  services.thermald.enable = true;

  system.stateVersion = "25.05";
}
