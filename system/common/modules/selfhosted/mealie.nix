{ config, lib, ... }:
let
  secretsRoot = "authelia/identity_providers/oidc/clients/mealie";
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "mealie";
  hostName = "nimbus";
  subdomain = "food";
  public = true;
  protected = true;
  serviceConfig = lib.mkMerge [
    {
      services.mealie = {
        enable = true;
        port = config.constants.ports.mealie;
        settings = {
          OIDC_AUTH_ENABLED = "true";
          OIDC_SIGNUP_ENABLED = "true";
          OIDC_CONFIGURATION_URL = "https://auth.sub0.net/.well-known/openid-configuration";
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
    }
    (lib.custom.mkPersistentSystemDir { directory = "/var/lib/private/mealie"; })
  ];
}
