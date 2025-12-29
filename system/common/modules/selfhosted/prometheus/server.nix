{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  port = 9092;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "prometheus";
  host = hosts.nimbus;
  inherit port;
  persistentDirectories = [
    {
      directory = "/var/lib/${config.services.prometheus.stateDir}";
      user = "prometheus";
      group = "prometheus";
    }
  ];
  serviceConfig = {
    services.prometheus = {
      enable = true;
      inherit port;
      globalConfig.scrape_interval = "15s";
      scrapeConfigs = [
        {
          job_name = "nut";
          static_configs = [
            {
              targets = [ (lib.custom.mkInternalFqdn config.constants "prometheus-nut" hosts.midnight.name) ];
            }
          ];
          metrics_path = "/ups_metrics";
          scheme = "https";
          scrape_interval = "10s";
          scrape_timeout = "10s";
        }
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                (lib.custom.mkInternalFqdn config.constants "prometheus-node" hosts.midnight.name)
                (lib.custom.mkInternalFqdn config.constants "prometheus-node" hosts.nimbus.name)
              ];
            }
          ];
          metrics_path = "/metrics";
          scheme = "https";
          scrape_interval = "10s";
          scrape_timeout = "10s";
        }
        {
          job_name = "caddy";
          static_configs = [
            {
              targets = [
                "localhost:2019"
              ];
            }
          ];
          metrics_path = "/metrics";
          scheme = "http";
          scrape_interval = "10s";
          scrape_timeout = "10s";
        }
        {
          job_name = "zfs";
          static_configs = [
            {
              targets = [ (lib.custom.mkInternalFqdn config.constants "prometheus-zfs" hosts.midnight.name) ];
            }
          ];
          metrics_path = "/metrics";
          scheme = "https";
          scrape_interval = "10s";
          scrape_timeout = "10s";
        }
      ];
    };
  };
}
