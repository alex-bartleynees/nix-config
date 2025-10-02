{ config, lib, pkgs, ... }:
lib.mkIf config.profiles.linux-laptop {
  # Inherit linux-desktop profile
  profiles.linux-desktop = true;

  # TLP power management
  tlpSettings = {
    enable = true;
    profile = "laptop";
  };

  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "lock";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  # Hibernation settings
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # Power button behavior
  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  # Power Management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  services.thermald.enable = true;

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [ brightnessctl powertop ];
}
