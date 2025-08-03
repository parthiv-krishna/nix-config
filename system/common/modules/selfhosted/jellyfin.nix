{ config, lib, ... }:
let
  inherit (config.constants) hosts tieredCache;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "jellyfin";
  hostName = hosts.midnight;
  port = 8096;
  subdomain = "tv";
  public = true;
  protected = false;
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
}
