{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  secretsRoot = "paperless";
  subdomain = "paperless";
  port = 28981;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "paperless";
  hostName = hosts.midnight;
  inherit port subdomain;
  public = true;
  protected = true;
  homepage = {
    category = config.constants.homepage.categories.storage;
    description = "Document management";
    icon = "sh-paperless-ngx";
  };

  oidcClient = {
    redirects = [ "/accounts/oidc/authelia/login/callback/" ];
    extraConfig = {
      client_name = "Paperless";
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      authorization_policy = "one_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    };
  };

  persistentDirectories = [ "/var/lib/paperless" ];

  serviceConfig = {
    services.paperless = {
      enable = true;
      address = "0.0.0.0";
      inherit port;
      environmentFile = config.sops.templates."paperless/environment".path;
      domain = lib.custom.mkPublicFqdn config.constants subdomain;
    };

    sops = {
      templates."paperless/environment" = {
        content = ''
          PAPERLESS_APPS=allauth.socialaccount.providers.openid_connect
          PAPERLESS_SOCIALACCOUNT_PROVIDERS={"openid_connect":{"SCOPE":["openid","profile","email"],"OAUTH_PKCE_ENABLED":true,"APPS":[{"provider_id":"authelia","name":"sub0.net SSO","client_id":"${
            config.sops.placeholder."${secretsRoot}/client_id"
          }","secret":"${
            config.sops.placeholder."${secretsRoot}/client_secret_orig"
          }","settings":{"server_url":"https://auth.sub0.net","token_auth_method":"client_secret_basic"}}]}}
        '';
        mode = "0444";
      };

      secrets = {
        "${secretsRoot}/client_id" = {
          mode = "0444";
        };
        "${secretsRoot}/client_secret_orig" = {
          mode = "0444";
        };
      };
    };
  };
}
