# Networking

{ config, pkgs, ... }: {
  networking.hostName = "nixos";

  # Enable networking
  networking.networkmanager.enable = true;
}
