{ config, ... }:
let
  inherit (config.constants) tieredCache;
in
{
  custom.selfhosted.ollama = {
    enable = true;
    hostName = "midnight";
    public = false;
    port = 11434;
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
    persistentDirs = [
      "/var/lib/private/ollama"
    ];
  };
}
