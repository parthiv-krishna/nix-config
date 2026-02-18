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
  homepage = {
    category = config.constants.homepage.categories.network;
    description = "Time-series database for monitoring";
    icon = "sh-prometheus";
  };
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
              targets = [ (lib.custom.mkPublicFqdn config.constants "prometheus-nut") ];
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
                (lib.custom.mkPublicFqdn config.constants "prometheus-node-midnight")
                (lib.custom.mkPublicFqdn config.constants "prometheus-node-nimbus")
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
                (lib.custom.mkPublicFqdn config.constants "prometheus-caddy-midnight")
                (lib.custom.mkPublicFqdn config.constants "prometheus-caddy-nimbus")
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
              targets = [ (lib.custom.mkPublicFqdn config.constants "prometheus-zfs") ];
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
              targets = [ (lib.custom.mkPublicFqdn config.constants "prometheus-smartmon") ];
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
                (lib.custom.mkPublicFqdn config.constants "prometheus-systemd-midnight")
                (lib.custom.mkPublicFqdn config.constants "prometheus-systemd-nimbus")
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
