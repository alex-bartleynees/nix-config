{ pkgs, theme, ... }:
let persistPaths = import ../../../shared/common-persist-paths.nix { };
in {
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
    image = theme.wallpaper;
  };

  sambaClient = { enable = true; };

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
    persistPaths = persistPaths.commonPersistPaths;
    resetSubvolumes = [ ]; # Reset all subvolumes except @snapshots
  };

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
