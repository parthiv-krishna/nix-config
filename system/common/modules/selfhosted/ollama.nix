{ config, lib, ... }:
let
  inherit (config.constants) tieredCache;
in
lib.custom.mkSelfHostedService {
  inherit
    config
    lib
    ;
  name = "ollama";
  hostName = "midnight";
  port = 11434;
  public = false;
  persistentDirectories = [ "/var/lib/private/ollama" ];
  serviceConfig = {
    services = {
      ollama = {
        enable = true;
        acceleration = "cuda";
        # allow remote access (via reverse proxy)
        host = "0.0.0.0";
        models = "${tieredCache.cachePool}/ollama";
      };

      # models are very large and not worth backing up
      restic.backups.digitalocean.exclude = [ "${tieredCache.basePool}/ollama/blobs" ];
    };
  };

}
