{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  secretsRoot = "mealie";
  port = 9000;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "mealie";
  host = hosts.midnight;
  inherit port;
  subdomain = "food";
  homepage = {
    category = config.constants.homepage.categories.tools;
    description = "Recipes";
    icon = "sh-mealie";
  };
  oidcClient = {
    redirects = [ "/login" ];
    extraConfig = {
      client_name = "Mealie";
      scopes = [
        "openid"
        "email"
        "profile"
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

  persistentDirectories = [ "/var/lib/private/mealie" ];
  serviceConfig = {
    services.mealie = {
      enable = true;
      inherit port;
      settings = {
        OIDC_AUTH_ENABLED = "true";
        OIDC_SIGNUP_ENABLED = "true";
        OIDC_CONFIGURATION_URL = "${lib.custom.mkPublicHttpsUrl config.constants "login"}/.well-known/openid-configuration";
        OIDC_AUTO_REDIRECT = "true";
        OIDC_ADMIN_GROUP = "admin";
        OIDC_USER_GROUP = "user";
      };
      credentialsFile = config.sops.templates."mealie/environment".path;
    };

    sops = {
      templates."mealie/environment" = {
        content = ''
          OIDC_CLIENT_ID="${config.sops.placeholder."${secretsRoot}/client_id"}"
          OIDC_CLIENT_SECRET="${config.sops.placeholder."${secretsRoot}/client_secret_orig"}"
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
