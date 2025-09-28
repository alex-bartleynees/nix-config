{ config, lib, ... }:
lib.mkIf config.profiles.base {
  # Common services across all machines
  tailscale.enable = true;
  docker.enable = true;
}