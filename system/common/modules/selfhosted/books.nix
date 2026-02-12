{
  config,
  lib,
  pkgs,
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
    backupServices = [
      "docker-shelfmark.service"
      "docker-gluetun-shelfmark.service"
    ];
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
      # gluetun VPN
      virtualisation.oci-containers.containers.gluetun-shelfmark = {
        image = "qmcgaw/gluetun:latest";
        ports = [ "8084:8084" ];
        volumes = [
          "${stateDir}/gluetun:/gluetun"
          "${config.sops.secrets."media/wg_config".path}:/gluetun/wireguard/wg0.conf:ro"
        ];
        environment = {
          VPN_SERVICE_PROVIDER = "custom";
          VPN_TYPE = "wireguard";
          VPN_ENDPOINT_PORT = "51820";
          TZ = config.time.timeZone;
          WIREGUARD_CONF_SECRETFILE = "/gluetun/wireguard/wg0.conf";
          WIREGUARD_MTU = "1280";
          FIREWALL_VPN_INPUT_PORTS = "8084";
          FIREWALL_INPUT_PORTS = "8084";
          DISABLE_IPV6 = "yes";
          DNS_KEEP_NAMESERVER = "on";
          DOT = "off";
        };
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun"
          # enable TCP MTU probing and lower MSS
          "--sysctl=net.ipv4.tcp_mtu_probing=1"
          "--sysctl=net.ipv4.ip_no_pmtu_disc=1"
        ];
      };

      # shelfmark container using gluetun's network
      virtualisation.oci-containers.containers.shelfmark = {
        image = "ghcr.io/calibrain/shelfmark:latest";
        dependsOn = [ "gluetun-shelfmark" ];
        extraOptions = [
          "--network=container:gluetun-shelfmark"
        ];
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
      };

      systemd = {
        tmpfiles.rules = [
          "d ${stateDir}/gluetun 0755 ${booksUser} ${booksGroup} -"
        ];

        # clamp MSS to avoid MTU issues with TLS handshakes
        services = {
          docker-gluetun-shelfmark = {
            postStart = ''
              sleep 2
              ${pkgs.docker}/bin/docker exec gluetun-shelfmark iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || true
            '';
          };

          # wait for gluetun
          docker-shelfmark = {
            after = [ "docker-gluetun-shelfmark.service" ];
            requires = [ "docker-gluetun-shelfmark.service" ];
            bindsTo = [ "docker-gluetun-shelfmark.service" ];
            serviceConfig = {
              RestartSec = "5s";
            };
          };
        };
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
