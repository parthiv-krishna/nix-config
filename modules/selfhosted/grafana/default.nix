{ config, lib, ... }:
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "grafana";
  hostName = "nimbus";
  public = true;
  protected = true;
  subdomain = "stats";
  serviceConfig = lib.mkMerge [
    {
      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_port = config.constants.ports.grafana;
            domain = "stats.${config.constants.domains.public}";
          };
        };
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = config.services.grafana.dataDir;
      user = "grafana";
      group = "grafana";
    })
  ];
}
