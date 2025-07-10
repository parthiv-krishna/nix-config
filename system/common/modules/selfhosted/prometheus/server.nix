{ config, lib, ... }:
let
  cfg = config.custom.selfhosted.prometheus;
  nutCfg = config.custom.selfhosted."prometheus-nut";
  nodeCfg = config.custom.selfhosted."prometheus-node";
  crowdsecCfg = config.custom.selfhosted.crowdsec;
in
{
  custom.selfhosted.prometheus = {
    enable = true;
    hostName = "nimbus";
    public = false;
    protected = false;
    port = 9092;
    config = {
      services.prometheus = {
        enable = true;
        inherit (cfg) port;
        globalConfig.scrape_interval = "15s";
        scrapeConfigs = [
          {
            job_name = "nut";
            static_configs = [
              {
                targets = [ nutCfg.fqdn.internal ];
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
                targets = [ "localhost:${toString crowdsecCfg.port}" ];
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
                targets = lib.map (
                  hostName: "${nodeCfg.subdomain}.${hostName}.${config.constants.domains.internal}"
                ) nodeCfg.hostNames;
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
    };
    persistentDirs = [
      {
        directory = "/var/lib/${config.services.prometheus.stateDir}";
        user = "prometheus";
        group = "prometheus";
      }
    ];
  };
}
