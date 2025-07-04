{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.reverse-proxy;
  subdomain = "auth";
in
{
  config = lib.mkIf (cfg.enable && cfg.publicFacing) (
    lib.mkMerge [
      {
        services = {
          authelia.instances.${cfg.autheliaInstanceName} = {
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
            settings = {
              server = {
                address = "tcp://:${toString config.constants.ports.authelia}";
                read_buffer_size = 32768;
                write_buffer_size = 32768;
              };
              theme = "dark";
              log.level = "debug";
              totp.issuer = config.constants.domains.public;
              authentication_backend.file.path = "${cfg.autheliaStateDir}/users_database.yml";
              access_control = {
                default_policy = "deny";
                rules = lib.mkAfter [
                  # service-specific rules are managed by lib.custom.mkSelfHostedService
                  # anyone can access the auth portal
                  {
                    domain_regex = "${subdomain}.${config.constants.domains.public}";
                    policy = "bypass";
                  }
                  # admins and users can access all domains
                  {
                    domain_regex = "^[a-z0-9]*\.?${config.constants.domains.public}$";
                    policy = "one_factor";
                    subject = [
                      "group:admin"
                      "group:user"
                    ];
                  }
                  # deny access to non-group domains
                  {
                    domain_regex = "^[a-z0-9]*\.?${config.constants.domains.public}$";
                    policy = "deny";
                  }
                ];
              };
              session = {
                cookies = [
                  {
                    name = "sub0_session";
                    domain = config.constants.domains.public;
                    authelia_url = "https://${subdomain}.${config.constants.domains.public}";
                    inactivity = "1 week";
                    expiration = "3 weeks";
                    remember_me = "1 month";
                  }
                ];
                redis = {
                  host = "localhost";
                  port = config.constants.ports.authelia-redis;
                };
              };
              regulation = {
                max_retries = 3;
                find_time = "2 minutes";
                ban_time = "5 minutes";
              };
              storage = {
                local.path = "${cfg.autheliaStateDir}/db.sqlite3";
              };
              # see https://www.authelia.com/integration/proxies/caddy/#implementation
              server.endpoints.authz.forward-auth.implementation = "ForwardAuth";
              # TODO: setup SMTP server for email
              notifier = {
                disable_startup_check = false;
                filesystem.filename = "${cfg.autheliaStateDir}/notification.txt";
              };
            };

            settingsFiles = [
              # yaml generator messes up secret formatting so do this manually
              (pkgs.writeText "extra_secrets.yml" ''
                session:
                  redis:
                    password: {{ secret "${config.sops.secrets."authelia/session/redis/password".path}" }}
              '')
              (
                let
                  domain = config.constants.domains.public;
                in
                pkgs.writeText "oidc_clients.yml" ''
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
                            - "https://actual.${domain}/openid/callback"
                          scopes:
                            - "email"
                            - "groups"
                            - "openid"
                            - "profile"
                          userinfo_signed_response_alg: "none"
                          token_endpoint_auth_method: "client_secret_basic"
                        - client_name: "Grafana"
                          client_id: {{ secret "${
                            config.sops.secrets."authelia/identity_providers/oidc/clients/grafana/client_id".path
                          }" }}
                          client_secret: {{ secret "${
                            config.sops.secrets."authelia/identity_providers/oidc/clients/grafana/client_secret".path
                          }" }}
                          public: false
                          authorization_policy: "one_factor"
                          require_pkce: true
                          pkce_challenge_method: "S256"
                          redirect_uris:
                            - "https://stats.${domain}/login/generic_oauth"
                          scopes:
                            - "openid"
                            - "profile"
                            - "groups"
                            - "email"
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
                          authorization_policy: "one_factor"
                          redirect_uris:
                            - "https://photos.${domain}/auth/login"
                            - "https://photos.${domain}/user-settings"
                            - "app.immich:///oauth-callback"
                          scopes:
                            - "openid"
                            - "profile"
                            - "email"
                          userinfo_signed_response_alg: "none"
                          token_endpoint_auth_method: "client_secret_post"
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
                            - "https://tv.${domain}/sso/OID/redirect/authelia"
                          scopes:
                            - "groups"
                            - "openid"
                            - "profile"
                          userinfo_signed_response_alg: "none"
                          token_endpoint_auth_method: "client_secret_post"
                        - client_name: "Mealie"
                          client_id: {{ secret "${
                            config.sops.secrets."authelia/identity_providers/oidc/clients/mealie/client_id".path
                          }" }}
                          client_secret: {{ secret "${
                            config.sops.secrets."authelia/identity_providers/oidc/clients/mealie/client_secret".path
                          }" }}
                          public: false
                          authorization_policy: "one_factor"
                          require_pkce: true
                          pkce_challenge_method: "S256"
                          redirect_uris:
                            - "https://food.sub0.net/login"
                          scopes:
                            - "openid"
                            - "email"
                            - "profile"
                            - "groups"
                          response_types:
                            - "code"
                          grant_types:
                            - "authorization_code"
                          access_token_signed_response_alg: "none"
                          userinfo_signed_response_alg: "none"
                          token_endpoint_auth_method: "client_secret_basic"
                ''
              )
            ];
          };

          # redis server for session storage
          redis.servers."authelia-${cfg.autheliaInstanceName}" = {
            enable = true;
            port = config.constants.ports.authelia-redis;
            settings = {
              maxmemory = "512mb";
              maxmemory-policy = "allkeys-lru";
              protected-mode = true;
            };
          };

          # add authentication to caddy
          caddy =
            let
              fqdn = "${subdomain}.${config.constants.domains.public}";
              port = config.constants.ports.authelia;
            in
            {
              extraConfig = ''
                (auth) {
                  forward_auth :${toString config.constants.ports.authelia}  {
                    uri /api/authz/forward-auth
                    copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
                  }
                }
              '';

              virtualHosts."${fqdn}" = {
                logFormat = ''
                  output file ${config.services.caddy.logDir}/access-${fqdn}.log {
                    roll_size 10MB
                    roll_keep 5
                    roll_keep_for 14d
                    mode 0640
                  }
                  level DEBUG
                '';
                extraConfig = ''
                  tls {
                    dns cloudflare {env.CF_API_TOKEN}
                  }
                  reverse_proxy localhost:${toString port}
                '';
              };
            };
        };

        # generate all secret declarations
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
              "authelia/identity_providers/oidc/clients/grafana/client_id"
              "authelia/identity_providers/oidc/clients/grafana/client_secret"
              "authelia/identity_providers/oidc/clients/immich/client_id"
              "authelia/identity_providers/oidc/clients/immich/client_secret"
              "authelia/identity_providers/oidc/clients/jellyfin/client_id"
              "authelia/identity_providers/oidc/clients/jellyfin/client_secret"
              "authelia/identity_providers/oidc/clients/mealie/client_id"
              "authelia/identity_providers/oidc/clients/mealie/client_secret"
            ];
          in
          lib.listToAttrs (
            map (
              secretPath:
              lib.nameValuePair secretPath {
                owner = config.services.authelia.instances.${cfg.autheliaInstanceName}.user;
              }
            ) allSecretPaths
          );
      }
      (lib.custom.mkPersistentSystemDir {
        directory = cfg.autheliaStateDir;
        inherit (config.services.authelia.instances.${cfg.autheliaInstanceName}) user group;
        mode = "0750";
      })
    ]
  );
}
