# Grafana Loki - centralized log storage
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "loki";
  subdomain = "logs";
  port = 3100;
  statusPath = "/ready";

  backupServices = [ "loki.service" ];

  persistentDirectories = [
    {
      directory = "/var/lib/loki";
      user = "loki";
      group = "loki";
    }
  ];

  serviceConfig = _cfg: _: {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server = {
          http_listen_address = "127.0.0.1";
          http_listen_port = 3100;
        };

        common = {
          path_prefix = "/var/lib/loki";
          replication_factor = 1;
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
        };

        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          retention_enabled = true;
          delete_request_store = "filesystem";
        };

        limits_config.retention_period = "30d";
        analytics.reporting_enabled = false;
      };
    };
  };
}
