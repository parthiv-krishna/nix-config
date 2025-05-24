{
  config,
  lib,
  pkgs,
  ...
}:
let
  instanceName = config.constants.domains.public;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "authelia";
  hostName = "vardar";
  subdomain = "auth";
  public = true;
  serviceConfig = lib.mkMerge [
    {
      services.authelia.instances.${instanceName} = {
        enable = true;
        secrets = with config.sops; {
          jwtSecretFile = secrets."authelia/identity_validation/reset_password/jwt_secret".path;
          oidcIssuerPrivateKeyFile = secrets."authelia/identity_providers/oidc/jwks/key".path;
          oidcHmacSecretFile = secrets."authelia/identity_providers/oidc/hmac_secret".path;
          sessionSecretFile = secrets."authelia/session/secret".path;
          storageEncryptionKeyFile = secrets."authelia/storage/encryption_key".path;
        };
        environmentVariables = {
          # enable templating filter for secrets
          X_AUTHELIA_CONFIG_FILTERS = "template";
        };
        # initial settings before secret injection
        settings = import ./settings.nix { inherit config instanceName; };
        settingsFiles = [
          (pkgs.writeText "extra_secrets.yml" ''
            session:
              redis:
                password: {{ secret "${config.sops.secrets."authelia/session/redis/password".path}" }}
          '')
          (pkgs.writeText "oidc_clients.yml" ''
            identity_providers:
              oidc:
                clients:
                  - client_name: "Actual"
                    client_id: {{ secret "${
                      config.sops.secrets."authelia/identity_providers/oidc/clients/actual/client_id".path
                    }" }}
                    client_secret: {{ secret "${
                      config.sops.secrets."authelia/identity_providers/oidc/clients/actual/client_secret".path
                    }" }}
                    public: false
                    authorization_policy: "one_factor"
                    redirect_uris:
                      - "https://actual.sub0.net/openid/callback"
                    scopes:
                      - "email"
                      - "groups"
                      - "openid"
                      - "profile"
                    userinfo_signed_response_alg: "none"
                    token_endpoint_auth_method: "client_secret_basic"
                  - client_name: "Immich"
                    client_id: {{ secret "${
                      config.sops.secrets."authelia/identity_providers/oidc/clients/immich/client_id".path
                    }" }}
                    client_secret: {{ secret "${
                      config.sops.secrets."authelia/identity_providers/oidc/clients/immich/client_secret".path
                    }" }}
                    public: false
                    authorization_policy: 'one_factor'
                    redirect_uris:
                      - 'https://immich.sub0.net/auth/login'
                      - 'https://immich.sub0.net/user-settings'
                      - 'app.immich:///oauth-callback'
                    scopes:
                      - 'openid'
                      - 'profile'
                      - 'email'
                    userinfo_signed_response_alg: 'none'
                  - client_name: "Jellyfin"
                    client_id: {{ secret "${
                      config.sops.secrets."authelia/identity_providers/oidc/clients/jellyfin/client_id".path
                    }" }}
                    client_secret: {{ secret "${
                      config.sops.secrets."authelia/identity_providers/oidc/clients/jellyfin/client_secret".path
                    }" }}
                    public: false
                    authorization_policy: "one_factor"
                    require_pkce: true
                    redirect_uris:
                      - "https://jellyfin.sub0.net/sso/OID/redirect/authelia"
                    scopes:
                      - "groups"
                      - "openid"
                      - "profile"
                    userinfo_signed_response_alg: "none"
                    token_endpoint_auth_method: "client_secret_post"
          '')
        ];
      };
      services.redis.servers."authelia-${instanceName}" = {
        enable = true;
        port = config.constants.services.authelia.redis-port;
        settings = {
          maxmemory = "128mb";
          maxmemory-policy = "allkeys-lru";
          protected-mode = true;
        };
      };
      sops.secrets =
        let
          allSecretPaths = [
            "authelia/identity_validation/reset_password/jwt_secret"
            "authelia/identity_providers/oidc/jwks/key"
            "authelia/identity_providers/oidc/hmac_secret"
            "authelia/session/secret"
            "authelia/session/redis/password"
            "authelia/storage/encryption_key"
            "authelia/identity_providers/oidc/clients/actual/client_id"
            "authelia/identity_providers/oidc/clients/actual/client_secret"
            "authelia/identity_providers/oidc/clients/immich/client_id"
            "authelia/identity_providers/oidc/clients/immich/client_secret"
            "authelia/identity_providers/oidc/clients/jellyfin/client_id"
            "authelia/identity_providers/oidc/clients/jellyfin/client_secret"
          ];
        in
        lib.listToAttrs (
          map (
            secretPath:
            lib.nameValuePair secretPath {
              owner = config.services.authelia.instances.${instanceName}.user;
              inherit (config.services.authelia.instances.${instanceName}) group;
            }
          ) allSecretPaths
        );
    }
    (lib.custom.mkPersistentSystemDir {
      directory = "/var/lib/authelia-${instanceName}";
      inherit (config.services.authelia.instances.${instanceName}) user group;
      mode = "0750";
    })
  ];
}
