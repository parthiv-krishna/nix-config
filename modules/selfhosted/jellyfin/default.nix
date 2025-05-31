{ config, lib, ... }:
let
  inherit (config.constants) tieredCache;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "jellyfin";
  hostName = "midnight";
  subdomain = "tv";
  public = true;
  protected = false;
  serviceConfig = lib.mkMerge [
    {
      services = {
        jellyfin = {
          enable = true;
          dataDir = "${tieredCache.cachePool}/jellyfin";
          cacheDir = "${tieredCache.cachePool}/jellyfin/cache";
        };
        # don't back up media
        restic.backups.digitalocean.exclude = [ "${tieredCache.basePool}/jellyfin/media" ];
      };
    }
  ];
}
