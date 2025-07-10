{ config, ... }:
let
  secretsRoot = "authelia/identity_providers/oidc/clients/mealie";
  cfg = config.custom.selfhosted.mealie;
  autheliaCfg = config.custom.selfhosted.authelia;
in
{
  custom.selfhosted.mealie = {
    enable = true;
    hostName = "nimbus";
    subdomain = "food";
    public = true;
    protected = true;
    port = 9000;
    config = {
      services.mealie = {
        enable = true;
        inherit (cfg) port;
        settings = {
          OIDC_AUTH_ENABLED = "true";
          OIDC_SIGNUP_ENABLED = "true";
          OIDC_CONFIGURATION_URL = "https://${autheliaCfg.fqdn.public}/.well-known/openid-configuration";
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
    persistentDirs = [
      "/var/lib/private/mealie"
    ];
  };
}
