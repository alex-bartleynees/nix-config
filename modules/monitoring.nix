{ config, lib, pkgs, ... }:
let cfg = config.monitoring;
in {
  options.monitoring = {
    enable =
      lib.mkEnableOption "Loki + Promtail + Grafana journal monitoring stack";

    grafana = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
      };
      domain = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
      };
      httpAddr = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };
      openFirewall = lib.mkEnableOption "open the Grafana port in the firewall";
    };

    loki.port = lib.mkOption {
      type = lib.types.port;
      default = 3100;
    };

    prometheus = {
      enable =
        lib.mkEnableOption "Prometheus + node_exporter with systemd collector";
      port = lib.mkOption {
        type = lib.types.port;
        default = 9090;
      };
      nodeExporterPort = lib.mkOption {
        type = lib.types.port;
        default = 9100;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = cfg.loki.port;
          log_level = "warn";
        };

        common = {
          ring.kvstore.store = "inmemory";
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
        };

        schema_config.configs = [{
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index.prefix = "index_";
          index.period = "24h";
        }];

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          ingestion_rate_mb = 16;
          ingestion_burst_size_mb = 32;
        };

        query_range.cache_results = true;

        query_scheduler.use_scheduler_ring = false;
      };
    };

    services.alloy = {
      enable = true;
      configPath = pkgs.writeText "config.alloy" ''
        loki.source.journal "system" {
          max_age    = "12h"
          forward_to = [loki.relabel.journal.receiver]
          labels = {
            job  = "systemd-journal",
            host = "${config.networking.hostName}",
          }
        }

        loki.relabel "journal" {
          forward_to = [loki.write.local.receiver]
          rule {
            source_labels = ["__journal__systemd_unit"]
            regex         = "(loki|alloy)\\.service"
            action        = "drop"
          }
          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
          rule {
            source_labels = ["__journal__hostname"]
            target_label  = "hostname"
          }
          rule {
            source_labels = ["__journal_priority_keyword"]
            target_label  = "level"
          }
          rule {
            source_labels = ["__journal__transport"]
            target_label  = "transport"
          }
        }

        loki.write "local" {
          endpoint {
            url = "http://localhost:${toString cfg.loki.port}/loki/api/v1/push"
          }
        }

        logging {
          level = "warn"
        }
      '';
      extraFlags = [ "--disable-reporting" ];
    };

    users.users.alloy = {
      isSystemUser = true;
      group = "alloy";
      extraGroups = [ "systemd-journal" ];
    };
    users.groups.alloy = { };

    impermanence.persistPaths =
      [ "/var/lib/loki" "/var/lib/alloy" "/var/lib/grafana" ]
      ++ lib.optionals cfg.prometheus.enable [ "/var/lib/prometheus2" ];

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = cfg.grafana.httpAddr;
          http_port = cfg.grafana.port;
          domain = cfg.grafana.domain;
        };
        security = {
          admin_user = "admin";
          secret_key =
            "$__file{${config.sops.secrets."grafana/secret_key".path}}";
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [{
          name = "Loki";
          type = "loki";
          url = "http://localhost:${toString cfg.loki.port}";
          isDefault = true;
        }] ++ lib.optionals cfg.prometheus.enable [{
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString cfg.prometheus.port}";
        }];
      };
    };

    services.prometheus = lib.mkIf cfg.prometheus.enable {
      enable = true;
      port = cfg.prometheus.port;
      scrapeConfigs = [{
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:${toString cfg.prometheus.nodeExporterPort}" ];
        }];
      }];
      exporters.node = {
        enable = true;
        port = cfg.prometheus.nodeExporterPort;
        enabledCollectors = [ "systemd" ];
      };
    };

    networking.firewall.allowedTCPPorts =
      lib.mkIf cfg.grafana.openFirewall [ cfg.grafana.port ];
  };
}
