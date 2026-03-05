# Prometheus server - time-series database for metrics from various exporters
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus";
  port = 9092;

  homepage = {
    category = "Network";
    description = "Time-series database for monitoring";
    icon = "sh-prometheus";
    status = "/-/healthy";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/prometheus2";
      user = "prometheus";
      group = "prometheus";
    }
  ];

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    {
      services.prometheus = {
        enable = true;
        port = 9092;
        globalConfig.scrape_interval = "15s";
        scrapeConfigs = [
          {
            job_name = "nut";
            static_configs = [
              {
                targets = [ (lib.custom.mkInternalFqdn config.constants "prometheus-nut" "midnight") ];
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
                  (lib.custom.mkInternalFqdn config.constants "prometheus-node" "midnight")
                  (lib.custom.mkInternalFqdn config.constants "prometheus-node" "nimbus")
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
                  (lib.custom.mkInternalFqdn config.constants "prometheus-caddy" "midnight")
                  (lib.custom.mkInternalFqdn config.constants "prometheus-caddy" "nimbus")
                ];
              }
            ];
            metrics_path = "/metrics";
            scheme = "https";
            scrape_interval = "10s";
            scrape_timeout = "10s";
          }
          {
            job_name = "zfs";
            static_configs = [
              {
                targets = [ (lib.custom.mkInternalFqdn config.constants "prometheus-zfs" "midnight") ];
              }
            ];
            metrics_path = "/metrics";
            scheme = "https";
            scrape_interval = "10s";
            scrape_timeout = "10s";
          }
          {
            job_name = "smartmon";
            static_configs = [
              {
                targets = [ (lib.custom.mkInternalFqdn config.constants "prometheus-smartmon" "midnight") ];
              }
            ];
            metrics_path = "/metrics";
            scheme = "https";
            scrape_interval = "60s";
            scrape_timeout = "10s";
          }
          {
            job_name = "systemd";
            static_configs = [
              {
                targets = [
                  (lib.custom.mkInternalFqdn config.constants "prometheus-systemd" "midnight")
                  (lib.custom.mkInternalFqdn config.constants "prometheus-systemd" "nimbus")
                ];
              }
            ];
            metrics_path = "/metrics";
            scheme = "https";
            scrape_interval = "15s";
            scrape_timeout = "10s";
          }
          {
            job_name = "jellyfin";
            static_configs = [
              {
                targets = [ (lib.custom.mkPublicFqdn config.constants "tv") ];
              }
            ];
            metrics_path = "/metrics";
            scheme = "https";
            scrape_interval = "30s";
            scrape_timeout = "10s";
          }
        ];
      };
    };
}
