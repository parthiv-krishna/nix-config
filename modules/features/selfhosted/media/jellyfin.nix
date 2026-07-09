# Jellyfin - media streaming
{ lib }:
let
  port = 8096;
  stateDir = "/var/lib/media/state/jellyfin";
in
lib.custom.mkSelfHostedFeature {
  name = "jellyfin";
  subdomain = "tv";
  inherit port;
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

  serviceConfig = _cfg: _: {
    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "media";
      dataDir = "${stateDir}/data";
      configDir = "${stateDir}/config";
      cacheDir = "${stateDir}/cache";
      logDir = "${stateDir}/log";
    };

    systemd = {
      tmpfiles.rules = [
        "d ${stateDir} 0700 jellyfin root - -"
        "d ${stateDir}/log 0700 jellyfin root - -"
        "d ${stateDir}/cache 0700 jellyfin root - -"
        "d ${stateDir}/data 0700 jellyfin root - -"
        "d ${stateDir}/config 0700 jellyfin root - -"
        "d /var/lib/media/library 0775 root media - -"
        "d /var/lib/media/library/shows 0775 root media - -"
        "d /var/lib/media/library/movies 0775 root media - -"
        "d /var/lib/media/library/music 0775 root media - -"
        "d /var/lib/media/library/books 0775 root media - -"
        "d /var/lib/media/library/audiobooks 0775 root media - -"
      ];
      services.jellyfin.serviceConfig.IOSchedulingPriority = 0;
    };

    users.users.jellyfin = {
      isSystemUser = true;
      group = "media";
      uid = 146;
    };
  };
}
