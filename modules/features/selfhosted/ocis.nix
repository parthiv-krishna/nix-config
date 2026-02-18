{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 9200;
  driveSubdomain = "drive";
  authSubdomain = "login";

  serviceModule = lib.custom.mkSelfHostedService {
    inherit config lib;
    name = "ocis";
    host = hosts.midnight;
    inherit port;
    subdomain = driveSubdomain;
    backupServices = [ "ocis.service" ];
    homepage = {
      category = config.constants.homepage.categories.storage;
      description = "General storage";
      icon = "sh-owncloud";
    };

    persistentDirectories = [
      {
        directory = "/var/lib/ocis";
        user = "ocis";
        group = "ocis";
        mode = "0700";
      }
    ];

    serviceConfig = {
      unfree.allowedPackages = [
        "ocis_5-bin"
      ];

      services.ocis = {
        enable = true;
        address = "127.0.0.1";
        inherit port;
        url = lib.custom.mkPublicHttpsUrl config.constants driveSubdomain;

        configDir = "/var/lib/ocis/config";
        environmentFile = config.sops.templates.ocis-environment.path;

        environment = {
          OCIS_INSECURE = "false";
          OCIS_LOG_LEVEL = "info";

          # disable TLS for HTTP services (caddy handles TLS)
          OCIS_HTTP_TLS_ENABLED = "false";
          OCIS_URL = lib.custom.mkPublicHttpsUrl config.constants driveSubdomain;

          WEB_UI_CONFIG_SERVER = lib.custom.mkPublicHttpsUrl config.constants driveSubdomain;

          WEB_OIDC_AUTHORITY = lib.custom.mkPublicHttpsUrl config.constants authSubdomain;

          PROXY_OIDC_ISSUER = lib.custom.mkPublicHttpsUrl config.constants authSubdomain;
          PROXY_OIDC_REWRITE_WELLKNOWN = "true";
          PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
          PROXY_OIDC_SKIP_USER_INFO = "false";

          # user provisioning from OIDC claims
          PROXY_AUTOPROVISION_ACCOUNTS = "true";
          PROXY_AUTOPROVISION_CLAIM_USERNAME = "preferred_username";
          PROXY_AUTOPROVISION_CLAIM_EMAIL = "email";
          PROXY_AUTOPROVISION_CLAIM_DISPLAYNAME = "name";
          PROXY_AUTOPROVISION_CLAIM_GROUPS = "groups";

          # proxy settings - tell oCIS it's behind a reverse proxy
          PROXY_TLS = "false";
          PROXY_INSECURE_BACKEND = "true";
        };
      };

      sops = {
        templates.ocis-environment = {
          content = ''
            JWT_SECRET=${config.sops.placeholder."ocis/jwt_secret"}
            WEB_OIDC_CLIENT_ID=${config.sops.placeholder."ocis/web_oidc_client_id"}
          '';
          owner = "ocis";
          group = "ocis";
        };
        secrets = {
          "ocis/jwt_secret" = {
            owner = "ocis";
            group = "ocis";
          };
          "ocis/web_oidc_client_id" = {
            owner = "ocis";
            group = "ocis";
          };
        };
      };
    };
  };
in
{
  imports = [ serviceModule ];

  # https://www.authelia.com/integration/openid-connect/clients/ocis/
  # authelia config for ocis is a bit more complicated
  # need to roll it a bit manually as it doesn't fit nicely into the formula in mkSelfHostedService
  config = {
    custom.selfhosted.autheliaExtraConfig = {
      identity_providers.oidc = {
        lifespans.custom.ocis = {
          access_token = "2 days";
          refresh_token = "3 days";
        };

        cors = {
          endpoints = [
            "authorization"
            "token"
            "revocation"
            "introspection"
            "userinfo"
          ];
        };
      };
    };

    custom.selfhosted.oidcClients = {
      "ocis" = {
        subdomain = driveSubdomain;
        redirects = [
          "/"
          "/oidc-callback.html"
          "/oidc-silent-redirect.html"
          "/apps/openidconnect/redirect"
        ];
        customRedirects = [ ];
        extraConfig = {
          client_name = "ownCloud Infinite Scale";
          public = true;
          lifespan = "ocis";
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          scopes = [
            "openid"
            "offline_access"
            "groups"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [
            "authorization_code"
            "refresh_token"
          ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "none";
        };
      };

      "ocis-desktop" = {
        subdomain = driveSubdomain;
        redirects = [ ];
        customRedirects = [
          "http://127.0.0.1"
          "http://localhost"
        ];
        extraConfig = {
          client_name = "ownCloud Infinite Scale (Desktop Client)";
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          scopes = [
            "openid"
            "offline_access"
            "groups"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [
            "authorization_code"
            "refresh_token"
          ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        };
      };

      "ocis-android" = {
        subdomain = driveSubdomain;
        redirects = [ ];
        customRedirects = [ "oc://android.owncloud.com" ];
        extraConfig = {
          client_name = "ownCloud Infinite Scale (Android)";
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          scopes = [
            "openid"
            "offline_access"
            "groups"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [
            "authorization_code"
            "refresh_token"
          ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        };
      };

      "ocis-ios" = {
        subdomain = driveSubdomain;
        redirects = [ ];
        customRedirects = [
          "oc://ios.owncloud.com"
          "oc.ios://ios.owncloud.com"
        ];
        extraConfig = {
          client_name = "ownCloud Infinite Scale (iOS)";
          authorization_policy = "one_factor";
          require_pkce = true;
          pkce_challenge_method = "S256";
          scopes = [
            "openid"
            "offline_access"
            "groups"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [
            "authorization_code"
            "refresh_token"
          ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        };
      };
    };
  };
}
