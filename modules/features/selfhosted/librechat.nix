# LibreChat - AI chat interface
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "librechat";
  subdomain = "ai";
  port = 3080;
  statusPath = "/health";

  backupServices = [ "librechat.service" ];

  homepage = {
    category = "Tools";
    description = "AI Chat Interface";
    icon = "sh-librechat";
  };

  oidcClient = {
    redirects = [ "/oauth/openid/callback" ];
    extraConfig = {
      client_name = "LibreChat";
      scopes = [
        "openid"
        "profile"
        "email"
      ];
      public = false;
      authorization_policy = "one_factor";
      userinfo_signing_algorithm = "none";
      token_endpoint_auth_method = "client_secret_post";
    };
  };

  persistentDirectories = [ "/var/lib/librechat" ];

  serviceConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      secretsRoot = "librechat";
      mkPublicHttpsUrl = lib.custom.mkPublicHttpsUrl config.constants;
      domain = config.constants.domains.public;
    in
    {
      services.librechat = {
        enable = true;
        enableLocalDB = true;
        env.PORT = 3080;

        settings = {
          version = "1.3.0";

          endpoints = {
            custom = [
              {
                name = "${domain} LLMs";
                apiKey = "not-needed";
                baseURL = "${mkPublicHttpsUrl "llm"}/v1";
                models = {
                  default = [ "medium" ];
                  fetch = true;
                };
                titleConvo = true;
                titleModel = "small";
              }
            ];
          };
        };

        credentials = {
          CREDS_KEY = config.sops.secrets."${secretsRoot}/creds_key".path;
          CREDS_IV = config.sops.secrets."${secretsRoot}/creds_iv".path;
          JWT_SECRET = config.sops.secrets."${secretsRoot}/jwt_secret".path;
          JWT_REFRESH_SECRET = config.sops.secrets."${secretsRoot}/jwt_refresh_secret".path;
          OPENID_SESSION_SECRET = config.sops.secrets."${secretsRoot}/openid_session_secret".path;
        };

        credentialsFile = config.sops.templates."librechat/environment".path;
      };

      # LibreChat only looks for OIDC upon startup - wait for availability
      systemd.services.librechat.serviceConfig.ExecStartPre = [
        "${lib.getExe pkgs.curl} --silent --show-error --fail --retry 30 --retry-delay 2 --retry-connrefused --connect-timeout 5 --max-time 10 ${mkPublicHttpsUrl "login"}/.well-known/openid-configuration"
      ];

      sops = {
        templates."librechat/environment" = {
          content = ''
            ALLOW_SOCIAL_LOGIN=true
            OPENID_BUTTON_LABEL=Log in with ${domain} SSO
            OPENID_ISSUER=${mkPublicHttpsUrl "login"}
            OPENID_CLIENT_ID=${config.sops.placeholder."${secretsRoot}/client_id"}
            OPENID_CLIENT_SECRET=${config.sops.placeholder."${secretsRoot}/client_secret_orig"}
            OPENID_CALLBACK_URL=/oauth/openid/callback
            OPENID_SCOPE=openid profile email
            DOMAIN_CLIENT=${mkPublicHttpsUrl "ai"}
            DOMAIN_SERVER=${mkPublicHttpsUrl "ai"}
          '';
          mode = "0400";
        };

        secrets = {
          "${secretsRoot}/creds_key" = { };
          "${secretsRoot}/creds_iv" = { };
          "${secretsRoot}/jwt_secret" = { };
          "${secretsRoot}/jwt_refresh_secret" = { };
          "${secretsRoot}/openid_session_secret" = { };
          "${secretsRoot}/client_id" = { };
          "${secretsRoot}/client_secret_orig" = { };
        };
      };

      # LibreChat uses mongodb, using CE avoids rebuilding it constantly
      services.mongodb.package = pkgs.mongodb-ce;
      custom.features.meta.unfree.allowedPackages = [ "mongodb-ce" ];
    };
}
