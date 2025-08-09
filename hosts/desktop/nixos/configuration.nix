# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, background, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot = { kernelPackages = pkgs.linuxPackages_latest; };

  # Hardware
  hardware.graphics = { enable = true; };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.xpadneo.enable = true;

  # Programs
  programs.zsh.enable = true;
  programs.nm-applet = { enable = true; };
  programs.dconf.enable = true;

  # Services
  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [
    pkgs.gnome-keyring
    pkgs.xdg-desktop-portal
  ];
  services.blueman.enable = true;
  services.upower.enable = true;
  services.acpid.enable = true;
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };
  services.udisks2.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Networking
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];
  networking.hostName = "nixos";

  # Virtualisation
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  # Enable kernel modules and VirtualBox service
  boot.kernelModules = [ "vboxdrv" "vboxnetadp" "vboxnetflt" ];
  # Add your user to vboxusers group
  users.extraGroups.vboxusers.members = [ "alexbn" ];

  # System wide settings
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

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
    profile = "blue"; # OpenRGB profile to use on startup
  };

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
