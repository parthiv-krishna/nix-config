# Calibre Web Automated - eBook library
{ lib }:
let
  stateDir = "/var/lib/books";
  booksUser = "books";
  booksGroup = "books";
  booksUid = 2100;
  booksGid = 2100;
in
lib.custom.mkSelfHostedFeature {
  name = "calibre-web-automated";
  subdomain = "books";
  port = 8083;

  backupServices = [ "docker-calibre-web-automated.service" ];

  homepage = {
    category = "Media";
    description = "Read eBooks";
    icon = "sh-calibre-web";
  };

  oidcClient = {
    redirects = [ "/login/generic/authorized" ];
    extraConfig = {
      client_name = "Calibre Web Automated";
      scopes = [
        "openid"
        "email"
        "profile"
      ];
      authorization_policy = "one_factor";
      require_pkce = false;
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      token_endpoint_auth_method = "client_secret_basic";
    };
  };

  persistentDirectories = [
    {
      directory = stateDir;
      user = booksUser;
      group = booksGroup;
      mode = "0755";
    }
  ];

  serviceConfig =
    _cfg:
    { config, ... }:
    {
      virtualisation.oci-containers.containers.calibre-web-automated = {
        image = "crocodilestick/calibre-web-automated:latest";
        ports = [ "8083:8083" ];
        volumes = [
          "${stateDir}/calibre-web-automated/config:/config"
          "${stateDir}/ingest:/cwa-book-ingest"
          "${stateDir}/library:/calibre-library"
        ];
        environment = {
          PUID = toString booksUid;
          PGID = toString booksGid;
          TZ = config.time.timeZone;
          TRUSTED_PROXY_COUNT = "1";
        };
      };

      users.users.${booksUser} = {
        isSystemUser = true;
        uid = booksUid;
        group = booksGroup;
      };
      users.groups.${booksGroup}.gid = booksGid;

      systemd.tmpfiles.rules = [
        "d ${stateDir}/calibre-web-automated/config 0755 ${booksUser} ${booksGroup} -"
        "d ${stateDir}/ingest 0755 ${booksUser} ${booksGroup} -"
        "d ${stateDir}/library 0755 ${booksUser} ${booksGroup} -"
        "d ${stateDir}/shelfmark/config 0755 ${booksUser} ${booksGroup} -"
      ];

      services.restic.backups.main.exclude = [
        "system/var/lib/containers"
      ];
    };
}
