# Shelfmark - book request service with VPN
{ lib }:
let
  stateDir = "/var/lib/books";
  booksUser = "books";
  booksGroup = "books";
  booksUid = 2100;
  booksGid = 2100;
in
lib.custom.mkSelfHostedFeature {
  name = "shelfmark";
  subdomain = "bookrequest";
  port = 8084;

  backupServices = [
    "docker-shelfmark.service"
    "docker-gluetun-shelfmark.service"
  ];

  homepage = {
    category = "Media";
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

  serviceConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Gluetun VPN
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
          "--sysctl=net.ipv4.tcp_mtu_probing=1"
          "--sysctl=net.ipv4.ip_no_pmtu_disc=1"
        ];
      };

      sops.secrets."media/wg_config" = { };

      # Shelfmark container using gluetun's network
      virtualisation.oci-containers.containers.shelfmark = {
        image = "ghcr.io/calibrain/shelfmark:latest";
        dependsOn = [ "gluetun-shelfmark" ];
        extraOptions = [
          "--network=container:gluetun-shelfmark"
        ];
        volumes = [
          "${stateDir}/shelfmark/config:/config"
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

        services = {
          docker-gluetun-shelfmark = {
            postStart = ''
              sleep 2
              ${pkgs.docker}/bin/docker exec gluetun-shelfmark iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || true
            '';
          };

          docker-shelfmark = {
            after = [ "docker-gluetun-shelfmark.service" ];
            requires = [ "docker-gluetun-shelfmark.service" ];
            bindsTo = [ "docker-gluetun-shelfmark.service" ];
            serviceConfig = {
              RestartSec = "5s";
            };
          };

          gluetun-vpn-refresh = {
            description = "Refresh gluetun VPN";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "systemctl restart docker-gluetun-shelfmark.service docker-shelfmark.service";
            };
          };
        };

        timers.gluetun-vpn-refresh = {
          description = "Refresh gluetun VPN every 3h";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnUnitActiveSec = "3h";
            Unit = "gluetun-vpn-refresh.service";
          };
        };
      };

      custom.features.meta.discord-notifiers.notifiers = {
        gluetun-vpn-refresh.enable = true;
      };
    };
}
