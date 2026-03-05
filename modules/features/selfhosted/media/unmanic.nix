# Unmanic - transcoding
{ lib }:
let
  mediaDir = "/var/lib/media";
  stateDir = "/var/lib/media/state";
in
lib.custom.mkSelfHostedFeature {
  name = "unmanic";
  subdomain = "transcode";
  port = 8889;

  homepage = {
    category = "Media Management";
    description = "Manage transcodes";
    icon = "sh-unmanic";
  };

  serviceConfig =
    _cfg:
    { config, ... }:
    let
      transcodeCache = "/var/cache/unmanic";
    in
    {
      virtualisation.oci-containers.containers.unmanic = {
        image = "ghcr.io/unmanic/unmanic:latest";
        ports = [ "8889:8888" ];
        volumes = [
          "${stateDir}/unmanic:/config"
          "${mediaDir}/library:/library"
          "${transcodeCache}:/tmp/unmanic"
        ];
        environment = {
          PUID = toString config.users.users.unmanic.uid;
          PGID = toString config.users.groups.media.gid;
        };
        devices = [
          "/dev/dri"
        ];
      };

      fileSystems.${transcodeCache} = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "size=32G"
          "mode=755"
        ];
      };

      users.groups.media = { };

      users.users.unmanic = {
        isSystemUser = true;
        group = "media";
        extraGroups = [ "video" ];
      };

      services.restic.backups.main.exclude = [
        "system/var/lib/containers"
      ];
    };
}
