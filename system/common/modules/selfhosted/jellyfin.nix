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
