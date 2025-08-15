{ config, pkgs, lib, ... }: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ fontconfig killall ];
}
