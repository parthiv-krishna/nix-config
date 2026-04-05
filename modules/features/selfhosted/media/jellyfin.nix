# Jellyfin - media streaming
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "jellyfin";
  subdomain = "tv";
  port = 8096;
  statusPath = "/health";

  backupServices = [ "jellyfin.service" ];

  homepage = {
    category = "Media";
    description = "Watch movies and TV";
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
      pkce_challenge_method = "S256";
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_post";
    };
  };

  persistentDirectories = [
    {
      directory = "/var/lib/media/state/jellyfin";
      user = "jellyfin";
      group = "media";
    }
  ];

  serviceConfig = _cfg: _: {
    services.jellyfin = {
      enable = true;
      group = "media";
      # Match nixarr's directory structure
      dataDir = "/var/lib/media/state/jellyfin/data";
      configDir = "/var/lib/media/state/jellyfin/config";
      logDir = "/var/lib/media/state/jellyfin/log";
      cacheDir = "/var/lib/media/state/jellyfin/cache";
    };
  };
}
