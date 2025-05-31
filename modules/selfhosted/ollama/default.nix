{ config, lib, ... }:
let
  name = "ollama";
  subdomain = name;
  hostName = "midnight";
  inherit (config.constants) tieredCache;
in
lib.custom.mkSelfHostedService {
  inherit
    config
    lib
    name
    subdomain
    hostName
    ;
  public = false;
  serviceConfig = lib.mkMerge [
    {
      services = {
        ollama = {
          enable = true;
          acceleration = "cuda";
          # allow remote access (via reverse proxy)
          host = "0.0.0.0";
          models = "${tieredCache.cachePool}/ollama";
        };

        # models are very large and not worth backing up
        restic.backups.digitalocean.exclude = [ "${tieredCache.basePool}/ollama/models" ];
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = "/var/lib/private/ollama";
    })
  ];

}
