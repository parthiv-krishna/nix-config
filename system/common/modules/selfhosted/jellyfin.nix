{ config, ... }:
let
  inherit (config.constants) tieredCache;
in
{
  custom.selfhosted.jellyfin = {
    enable = true;
    hostName = "midnight";
    subdomain = "tv";
    public = true;
    protected = false;
    port = 8096;
    serviceConfig = {
      services = {
        jellyfin = {
          enable = true;
          dataDir = "${tieredCache.cachePool}/jellyfin";
          cacheDir = "${tieredCache.cachePool}/jellyfin/cache";
        };
        # don't back up media
        restic.backups.digitalocean.exclude = [
          "${tieredCache.basePool}/jellyfin/cache"
          "${tieredCache.basePool}/jellyfin/media"
        ];
      };
    };
  };
}
