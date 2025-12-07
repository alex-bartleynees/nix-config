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
    configureUdpGro = lib.mkEnableOption "UDP GRO configuration for improved routing performance";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.routingFeatures;
    };

    environment.systemPackages = [ pkgs.tailscale ];

    # Configure UDP GRO for exit nodes and subnet routers
    # See: https://tailscale.com/s/ethtool-config-udp-gro
    systemd.services.tailscale-udp-gro = lib.mkIf cfg.configureUdpGro {
      description = "Configure UDP GRO for Tailscale routing";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        NETDEV=$(${pkgs.iproute2}/bin/ip -o route get 8.8.8.8 | cut -f 5 -d " ")
        if [ -n "$NETDEV" ]; then
          ${pkgs.ethtool}/bin/ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off || true
        fi
      '';
    };
  };
}
