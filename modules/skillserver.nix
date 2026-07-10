{ config, lib, pkgs, inputs, ... }:
let cfg = config.skillserver;
in {
  options.skillserver = {
    enable =
      lib.mkEnableOption "the netclaw skill registry server (skillserver)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port skillserver listens on.";
    };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      example = "http://10.0.1.2:8080";
      description = ''
        Base URL used for absolute URLs in discovery responses
        (SKILLSERVER__BASEURL) — must be an address consumers can actually
        reach, not necessarily localhost.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open skillserver.port in the firewall.";
    };

    apiKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "skillserver/apikey";
      description = ''
        sops secret path holding the bootstrap API key. Only used on
        skillserver's first run — it hashes and stores it, then ignores this
        env var on every subsequent start once any key exists in its DB.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "skillserver";
      description = "System user skillserver runs as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "skillserver";
      description = "System group skillserver runs as.";
    };
  };

  config = lib.mkIf cfg.enable {
    # A separate trust domain from any netclaw agent that might run alongside
    # it — skillserver is network-facing with its own API-key auth surface,
    # potentially serving multiple netclaw instances, so it gets its own
    # dedicated unprivileged system user rather than reusing an agent's.
    users.users.${cfg.user} = lib.mkIf (cfg.user == "skillserver") {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = lib.mkIf (cfg.group == "skillserver") { };

    sops.secrets.${cfg.apiKeySecret} = { };
    sops.templates."skillserver-env" = {
      # Default sops-nix ownership (root:root 0400) is correct — read by a
      # system service before it drops to User=${cfg.user}.
      content = ''
        SKILLSERVER__APIKEY=${config.sops.placeholder.${cfg.apiKeySecret}}
      '';
    };

    systemd.services.skillserver = {
      description = "netclaw skill registry server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        ASPNETCORE_URLS = "http://0.0.0.0:${toString cfg.port}";
        SKILLSERVER__DATAPATH = "/var/lib/skillserver";
        SKILLSERVER__BASEURL = cfg.baseUrl;
      };
      serviceConfig = {
        ExecStart = "${
            inputs.netclaw.packages.${pkgs.stdenv.hostPlatform.system}.skillserver
          }/bin/skillserver";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "skillserver";
        Restart = "on-failure";
        RestartSec = 5;
        EnvironmentFile = config.sops.templates."skillserver-env".path;
      };
    };

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
