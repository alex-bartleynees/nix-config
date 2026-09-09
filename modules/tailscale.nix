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
    configureUdpGro = lib.mkEnableOption
      "UDP GRO configuration for improved routing performance";
    peerRelayPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      example = 40000;
      description = ''
        UDP port to run a Tailscale peer relay server on, or null to not be a
        relay. Unlike ordinary Tailscale traffic this is an inbound listener
        that peers dial into, so the port is opened in the firewall. Off-LAN
        peers additionally need the port forwarded to this host on the
        router, and the tailnet policy needs a matching ACL grant before any
        client will actually use the relay.
        See: https://tailscale.com/docs/features/peer-relay
      '';
    };
    noLogsNoSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Disable tailscaled client logging via --no-logs-no-support.
        This opts the device out of Tailscale support that would require
        that telemetry for debugging.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.routingFeatures;
      extraDaemonFlags =
        lib.optionals cfg.noLogsNoSupport [ "--no-logs-no-support" ];
      extraSetFlags = lib.optionals (cfg.peerRelayPort != null)
        [ "--relay-server-port=${toString cfg.peerRelayPort}" ];
    };

    # A peer relay is dialed *into* by tailnet peers, so unlike ordinary
    # Tailscale traffic it can't rely on hole punching from an outbound
    # connection — the listening port has to accept inbound UDP. Peers are
    # still authenticated as tailnet nodes before the relay will carry
    # anything, and it forwards without decrypting, so this doesn't expose
    # the host to arbitrary internet traffic.
    networking.firewall.allowedUDPPorts =
      lib.optional (cfg.peerRelayPort != null) cfg.peerRelayPort;

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
