{ config, lib, ... }:
let
  instance = config.constants.domains.public;

  # automatically declare secret and inject into configuration
  mkSecret =
    secretPath:
    let
      attrPath = lib.splitString "/" secretPath;
      # path with prefix for lookup in sops file
      fullSecretPath = "authelia/${secretPath}";
      # secret template for authelia configuration
      secretTemplate = "{{ secret ${config.sops.secrets.${fullSecretPath}.path} }}";
    in
    {
      sops.secrets.${fullSecretPath} = { };
      services.authelia.instances.${instance}.settings = lib.setAttrByPath attrPath secretTemplate;
    };
in
{

}
// lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "authelia";
  hostName = "vardar";
  subdomain = "auth";
  public = true;
  serviceConfig = lib.mkMerge [
    {
      services.authelia.instances.${instance} = {
        enable = true;
        secrets.manual = true;
        environmentVariables = {
          # Enable templating filter for secrets
          X_AUTHELIA_CONFIG_FILTERS = "template";
        };
        settings = lib.mkMerge [
          {
            server.address = "tcp://:9091";
            theme = "dark";
            log = {
              level = "warn";
              format = "text";
              file_path = "/log/authelia.log";
            };
            totp.issuer = "sub0.net";
            authentication_backend.file.path = "/data/users_database.yml";
            access_control = {
              default_policy = "deny";
              rules = [
                {
                  domain_regex = "[a-z0-9]*.sub0.net";
                  policy = "bypass";
                }
              ];
            };
            session = {
              cookies = [
                {
                  name = "sub0_session";
                  domain = "sub0.net";
                  authelia_url = "https://auth.sub0.net";
                  expiration = "1 hour";
                  inactivity = "5 minutes";
                }
              ];
              redis = {
                host = "redis";
                port = 6379;
              };
            };
            regulation = {
              max_retries = 3;
              find_time = "2 minutes";
              ban_time = "5 minutes";
            };
            storage = {
              local.path = "/data/db.sqlite3";
            };
            # TODO: setup SMTP server for email
            notifier = {
              disable_startup_check = false;
              filesystem.filename = "/data/notification.txt";
            };
            identity_providers.oidc = {
              jwks = {
                main = {
                  algorithm = "RS256";
                  use = "sig";
                };
              };
              clients = {
                actual = {
                  client_name = "Actual";
                  public = false;
                  authorization_policy = "one_factor";
                  redirect_uris = [ "https://actual.sub0.net/openid/callback" ];
                  scopes = [
                    "email"
                    "groups"
                    "openid"
                    "profile"
                  ];
                  userinfo_signed_response_alg = "none";
                  token_endpoint_auth_method = "client_secret_basic";
                };
                immich = {
                  client_name = "Immich";
                  public = false;
                  authorization_policy = "one_factor";
                  redirect_uris = [
                    "https://immich.sub0.net/auth/login"
                    "https://immich.sub0.net/user-settings"
                    "app.immich:///oauth-callback"
                  ];
                  scopes = [
                    "openid"
                    "profile"
                    "email"
                  ];
                  userinfo_signed_response_alg = "none";
                };
                jellyfin = {
                  client_name = "Jellyfin";
                  public = false;
                  authorization_policy = "one_factor";
                  require_pkce = true;
                  redirect_uris = [ "https://jellyfin.sub0.net/sso/OID/redirect/authelia" ];
                  scopes = [
                    "groups"
                    "openid"
                    "profile"
                  ];
                  userinfo_signed_response_alg = "none";
                  token_endpoint_auth_method = "client_secret_post";
                };
              };
            };
          }
        ];
      };
    }
    # Secret declarations and injections
    (mkSecret "identity_validation/reset_password/jwt_secret")
    (mkSecret "session/secret")
    (mkSecret "session/redis/password")
    (mkSecret "storage/encryption_key")
    (mkSecret "identity_providers/oidc/hmac_secret")
    (mkSecret "identity_providers/oidc/jwks/main/key")
    (mkSecret "identity_providers/oidc/clients/actual/client_id")
    (mkSecret "identity_providers/oidc/clients/actual/client_secret")
    (mkSecret "identity_providers/oidc/clients/immich/client_id")
    (mkSecret "identity_providers/oidc/clients/immich/client_secret")
    (mkSecret "identity_providers/oidc/clients/jellyfin/client_id")
    (mkSecret "identity_providers/oidc/clients/jellyfin/client_secret")
    (lib.custom.mkPersistentSystemDir { directory = "/var/lib/private/authelia"; })
  ];
}
