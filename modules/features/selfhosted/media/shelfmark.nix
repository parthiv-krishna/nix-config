# Shelfmark - book request service with VPN
{ lib }:
let
  port = 8084;
  stateDir = "/var/lib/books";
  booksUser = "books";
  booksGroup = "books";
  booksUid = 2100;
  booksGid = 2100;
in
lib.custom.mkSelfHostedFeature {
  name = "shelfmark";
  subdomain = "bookrequest";
  inherit port;
  vpn = true;

  backupServices = [ "shelfmark.service" ];

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
    let
      podman = "${pkgs.podman}/bin/podman";
      image = "ghcr.io/calibrain/shelfmark:latest";

      shelfmarkImage = pkgs.writeShellScript "shelfmark-image" ''
        ${podman} image exists ${image} || ${podman} pull ${image}
      '';

      shelfmarkStart = pkgs.writeShellScript "shelfmark-start" ''
        exec ${podman} run \
          --rm \
          --name=shelfmark \
          --pull=never \
          --network=host \
          -e PUID=${toString booksUid} \
          -e PGID=${toString booksGid} \
          -e TZ=${config.time.timeZone} \
          -e CALIBRE_WEB_URL=${lib.custom.mkPublicHttpsUrl config.constants "books"} \
          -v ${stateDir}/shelfmark/config:/config \
          -v ${stateDir}/ingest:/books \
          ${image}
      '';

      shelfmarkStop = pkgs.writeShellScript "shelfmark-stop" ''
        ${podman} stop -t 10 shelfmark || true
      '';
    in
    {
      virtualisation.podman.enable = true;

      systemd = {
        tmpfiles.rules = [
          "d ${stateDir}/shelfmark/config 0755 ${booksUser} ${booksGroup} -"
          "d ${stateDir}/ingest 0755 ${booksUser} ${booksGroup} -"
        ];

        services = {
          shelfmark-image = {
            description = "Pull Shelfmark image";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = shelfmarkImage;
            };
          };

          shelfmark = {
            description = "Shelfmark";
            after = [ "shelfmark-image.service" ];
            requires = [ "shelfmark-image.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStartPre = "-${podman} rm -f shelfmark";
              ExecStart = shelfmarkStart;
              ExecStop = shelfmarkStop;
              Restart = "on-failure";
              RestartSec = "5s";
            };
          };
        };
      };

      users.users.${booksUser} = {
        isSystemUser = true;
        uid = booksUid;
        group = booksGroup;
      };
      users.groups.${booksGroup}.gid = booksGid;

      custom.features.storage.restic.excludePaths = [
        "/var/lib/containers"
      ];
    };
}
