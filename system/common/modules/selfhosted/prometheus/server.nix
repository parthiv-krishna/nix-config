{ config, lib, ... }:
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "prometheus";
  hostName = "nimbus";
  public = false;
  protected = false;
  serviceConfig = lib.mkMerge [
    {
      services.prometheus = {
        enable = true;
        port = config.constants.ports.prometheus;
        globalConfig.scrape_interval = "15s";
        scrapeConfigs = [
          {
            job_name = "nut";
            static_configs = [
              {
                targets = [ "prometheus-nut.vardar.${config.constants.domains.internal}" ];
              }
            ];
            metrics_path = "/ups_metrics";
            scheme = "https";
            scrape_interval = "10s";
            scrape_timeout = "10s";
          }
          {
            job_name = "crowdsec";
            static_configs = [
              {
                targets = [ "localhost:${toString config.constants.ports.prometheus-crowdsec}" ];
              }
            ];
            metrics_path = "/metrics";
            scheme = "http";
            scrape_interval = "10s";
            scrape_timeout = "10s";
          }
          {
            job_name = "node";
            static_configs = [
              {
                targets = [
                  "prometheus-node.midnight.${config.constants.domains.internal}"
                  "prometheus-node.nimbus.${config.constants.domains.internal}"
                  "prometheus-node.vardar.${config.constants.domains.internal}"
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
        ];
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = "/var/lib/${config.services.prometheus.stateDir}";
      user = "prometheus";
      group = "prometheus";
    })
  ];
}
