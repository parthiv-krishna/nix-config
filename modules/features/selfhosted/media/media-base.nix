# Media base - shared media config (persistence, group, backups)
{ lib }:
let
  mediaDir = "/var/lib/media";
in
lib.custom.mkFeature {
  path = [
    "selfhosted"
    "media-base"
  ];

  systemConfig = _cfg: _: {
    environment.persistence."/persist/system".directories = [
      {
        directory = mediaDir;
        user = "root";
        group = "root";
        mode = "0755";
      }
    ];

    users.groups.media.gid = 169;

    custom.features.storage.restic.excludePaths = [
      "/var/lib/media/library"
      "/var/lib/media/torrents"
    ];
  };
}
