{ config, lib, ... }:
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "actual";
  hostName = "nimbus";
  public = true;
  serviceConfig = lib.mkMerge [
    {
      services.actual = {
        enable = true;
        settings = {
          inherit (config.constants.services.actual) port;
        };
      };
    }
    (lib.custom.mkPersistentSystemDir { directory = "/var/lib/private/actual"; })
  ];
}
