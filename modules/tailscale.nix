{ config, lib, pkgs, ... }:
let cfg = config.tailscale;
in {
  options.tailscale = {
    enable = lib.mkEnableOption "Tailscale support";
    routingFeatures = lib.mkOption {
      type = lib.types.enum [ "client" "server" "both" ];
      default = "client";
      description = "Tailscale routing features";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.routingFeatures;
    };

    environment.systemPackages = [ pkgs.tailscale ];
  };
}
