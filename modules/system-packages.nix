{ config, pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [ fontconfig killall libnotify ];
}
