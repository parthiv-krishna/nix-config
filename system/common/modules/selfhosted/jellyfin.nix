{ config, lib, ... }:
let
  inherit (config.constants) hosts;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "jellyfin";
  hostName = hosts.midnight;
  port = 8096;
  subdomain = "tv";
  public = true;
  protected = false;
  homepage = {
    category = config.constants.homepage.categories.media;
    description = "Movies and TV";
    icon = "sh-jellyfin";
  };
  oidcClient = {
    redirects = [ "/sso/OID/redirect/authelia" ];
    extraConfig = {
      client_name = "Jellyfin";
      scopes = [
        "groups"
        "openid"
        "profile"
      ];
      authorization_policy = "one_factor";
      require_pkce = true;
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_post";
    };
  };

  serviceConfig = {
    services = {
      jellyfin = {
        enable = true;
        dataDir = "/var/lib/jellyfin";
        cacheDir = "/var/lib/jellyfin/cache";
      };

    };

    # don't backup media
    services.restic.backups.digitalocean.exclude = [
      "system/var/lib/jellyfin/cache"
      "system/var/lib/jellyfin/media"
    ];

  };
}
