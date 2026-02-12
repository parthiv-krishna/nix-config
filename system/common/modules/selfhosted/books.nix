{
  config,
  lib,
  ...
}:
let
  host = config.constants.hosts.midnight;
  stateDir = "/var/lib/books";
  booksUser = "books";
  booksGroup = "books";
  booksUid = 2100;
  booksGid = 2100;

  cwa = lib.custom.mkSelfHostedService {
    inherit config lib;
    name = "calibre-web-automated";
    inherit host;
    port = 8083;
    subdomain = "books";
    backupServices = [ "docker-calibre-web-automated.service" ];
    homepage = {
      category = config.constants.homepage.categories.media;
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
        require_pkce = true;
        pkce_challenge_method = "S256";
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
    serviceConfig = {
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

      # don't backup container images
      services.restic.backups.main.exclude = [
        "system/var/lib/containers"
      ];
    };
  };

  shelfmark = lib.custom.mkSelfHostedService {
    inherit config lib;
    name = "shelfmark";
    inherit host;
    port = 8084;
    subdomain = "bookrequest";
    backupServices = [ "docker-shelfmark.service" ];
    homepage = {
      category = config.constants.homepage.categories.media;
      description = "Request a book";
      icon = "sh-shelfmark";
    };
    oidcClient = {
      redirects = [ "/api/auth/oidc/callback" ];
      extraConfig = {
        client_name = "Shelfmark";
        scopes = [
          "openid"
          "email"
          "profile"
        ];
        authorization_policy = "one_factor";
        require_pkce = true;
        pkce_challenge_method = "S256";
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "client_secret_basic";
      };
    };
    serviceConfig = {
      virtualisation.oci-containers.containers.shelfmark = {
        image = "ghcr.io/calibrain/shelfmark:latest";
        volumes = [
          "${stateDir}/shelfmark/config:/config"
          # downloads go to CWA's ingest dir for automatic library import
          "${stateDir}/ingest:/books"
        ];
        environment = {
          PUID = toString booksUid;
          PGID = toString booksGid;
          TZ = config.time.timeZone;
          CALIBRE_WEB_URL = lib.custom.mkPublicHttpsUrl config.constants "books";
        };
        extraOptions = [ "--network=host" ];
      };

      systemd.services.docker-shelfmark = {
        vpnConfinement = {
          enable = true;
          vpnNamespace = "wg";
        };
        after = [ "wg.service" ];
        requires = [ "wg.service" ];
      };
    };
  };
in
{
  config = lib.mkMerge [
    cwa.config
    shelfmark.config
  ];
}
