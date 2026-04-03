# Prometheus server - time-series database for metrics from various exporters
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus";
  port = 9092;
  statusPath = "/-/healthy";

  homepage = {
    category = "Network";
    description = "Time-series database for monitoring";
    icon = "sh-prometheus";
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
    let
      inherit (config.custom.features.selfhosted) serviceMetadata;

      # null means don't monitor uptime
      monitoredServices = lib.filterAttrs (_: svc: svc.statusPath != null) serviceMetadata;
    in
    {
      services.prometheus = {
        enable = true;
        port = 9092;
        # extraFlags = [ "--web.enable-admin-api" ];
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
          {
            job_name = "blackbox";
            metrics_path = "/probe";
            params = {
              module = [ "http_2xx" ];
            };
            static_configs = lib.mapAttrsToList (_name: svc: {
              targets = [ "${lib.custom.mkPublicHttpsUrl config.constants svc.subdomain}${svc.statusPath}" ];
              labels = {
                service_name = svc.name;
                service_url = lib.custom.mkPublicFqdn config.constants svc.subdomain;
              };
            }) monitoredServices;
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "__param_target";
              }
              {
                source_labels = [ "__param_target" ];
                target_label = "instance";
              }
              {
                target_label = "__address__";
                replacement = lib.custom.mkInternalFqdn config.constants "prometheus-blackbox" "nimbus";
              }
            ];
            scheme = "https";
            scrape_interval = "30s";
            scrape_timeout = "15s";
          }
        ];
      };
    };
}
