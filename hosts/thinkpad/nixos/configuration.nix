{ pkgs, ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  profiles.linux-desktop = true;

  # Lid close
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "lock";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  # Define time delay for hibernation
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # Power button
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  # Power Management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  services.thermald.enable = true;

  # Packages
  environment.systemPackages = with pkgs; [ brightnessctl powertop ];

  system.stateVersion = "25.05";
}
