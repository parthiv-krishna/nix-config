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

  serviceConfig = _cfg: _: {
    nixarr.jellyfin = {
      enable = true;
    };
  };
}
