{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  secretsRoot = "open-webui";
  port = 8041;
  subdomain = "ai";
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "open-webui";
  host = hosts.midnight;
  inherit port subdomain;
  homepage = {
    category = config.constants.homepage.categories.tools;
    description = "AI Models";
    icon = "sh-open-webui";
  };
  oidcClient = {
    redirects = [ "/oauth/oidc/callback" ];
    extraConfig = {
      client_name = "Open WebUI";
      scopes = [
        "openid"
        "email"
        "profile"
        "groups"
      ];
      public = false;
      authorization_policy = "one_factor";
      require_pkce = false;
      pkce_challenge_method = "";
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    };
  };

  persistentDirectories = [ "/var/lib/private/open-webui" ];
  serviceConfig = {
    services.open-webui = {
      enable = true;
      inherit port;
      environmentFile = config.sops.templates."open-webui/environment".path;
    };

    unfree.allowedPackages = [
      "open-webui"
    ];

    sops =
      let
        mkPublicHttpsUrl = lib.custom.mkPublicHttpsUrl config.constants;
      in
      {
        templates."open-webui/environment" = {
          content = ''
            WEBUI_URL=${mkPublicHttpsUrl subdomain}
            ENABLE_PERSISTENT_CONFIG=false
            ENABLE_OAUTH_SIGNUP=true
            OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true
            OAUTH_CLIENT_ID="${config.sops.placeholder."${secretsRoot}/client_id"}"
            OAUTH_CLIENT_SECRET="${config.sops.placeholder."${secretsRoot}/client_secret_orig"}"
            OPENID_PROVIDER_URL=${mkPublicHttpsUrl "login"}/.well-known/openid-configuration
            OAUTH_PROVIDER_NAME=${config.constants.domains.public} SSO
            OAUTH_SCOPES=openid email profile groups
            ENABLE_OAUTH_ROLE_MANAGEMENT=true
            OAUTH_ALLOWED_ROLES=open-webui,user,admin
            OAUTH_ADMIN_ROLES=admin
            OAUTH_ROLES_CLAIM=groups
          '';
          mode = "0444";
        };

        secrets = {
          "${secretsRoot}/client_id" = { };
          "${secretsRoot}/client_secret_orig" = { };
        };
      };
  };
}
