{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  secretsRoot = "authelia/identity_providers/oidc/clients/open-webui";
  port = 8041;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "open-webui";
  hostName = hosts.midnight;
  inherit port;
  subdomain = "ai";
  public = true;
  protected = true;
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

  persistentDirectories = [ "/var/lib/open-webui" ];
  serviceConfig = {
    services.open-webui = {
      enable = true;
      inherit port;
      environmentFile = config.sops.templates."mealie/environment".path;
    };

    unfree.allowedPackages = [
      "open-webui"
    ];

    sops = {
      templates."mealie/environment" = {
        content = ''
          WEBUI_URL = "https://ai.sub0.net";
          ENABLE_OAUTH_SIGNUP = true;
          OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true
          OAUTH_CLIENT_ID="${config.sops.placeholder."${secretsRoot}/client_id"}"
          OAUTH_CLIENT_SECRET="${config.sops.placeholder."${secretsRoot}/client_secret_orig"}"
          OPENID_PROVIDER_URL=https://auth.sub0.net/.well-known/openid-configuration
          OAUTH_PROVIDER_NAME=Authelia
          OAUTH_SCOPES=openid email profile groups
          ENABLE_OAUTH_ROLE_MANAGEMENT=true
          OAUTH_ALLOWED_ROLES=open-webui,user,admin
          OAUTH_ADMIN_ROLES=admin
          OAUTH_ROLES_CLAIM=groups
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
