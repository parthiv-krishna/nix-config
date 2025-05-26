{ config, lib, ... }:
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
        jellyfin.enable = true;

        # don't back up media
        restic.backups.digitalocean.exclude = [ "/var/lib/jellyfin/media" ];
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = config.services.jellyfin.dataDir;
      inherit (config.services.jellyfin) user group;
    })
  ];
}
