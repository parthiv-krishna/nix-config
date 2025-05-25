{ config, lib, ... }:
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "jellyfin";
  hostName = "midnight";
  public = true;
  serviceConfig = lib.mkMerge [
    {
      services.jellyfin = {
        enable = true;
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = config.services.jellyfin.dataDir;
      inherit (config.services.jellyfin) user group;
    })
  ];
}
