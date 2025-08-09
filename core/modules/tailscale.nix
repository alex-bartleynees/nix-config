{ config, lib, pkgs, ... }:
let cfg = config.tailscale;
in {
  options.tailscale = { enable = lib.mkEnableOption "Tailscale support"; };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    environment.systemPackages = [ pkgs.tailscale ];
  };
}
