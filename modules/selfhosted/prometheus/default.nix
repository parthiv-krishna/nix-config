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
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = "/var/lib/${config.services.prometheus.stateDir}";
      user = "prometheus";
      group = "prometheus";
    })
  ];
}
