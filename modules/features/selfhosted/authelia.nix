# Authelia - authentication portal and OIDC provider
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "authelia";
  subdomain = "login";
  port = 9091;
  statusPath = "/api/health";

  homepage = {
    category = "Network";
    description = "Authentication portal";
    icon = "sh-authelia";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/authelia-sub0.net";
      user = "authelia-sub0.net";
      group = "authelia-sub0.net";
      mode = "0750";
    }
  ];

  serviceConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      redisPort = 6379;
      instanceName = config.constants.domains.public;
      stateDir = "/var/lib/authelia-${instanceName}";
    in
    {
      # Register backup services (authelia + redis)
      custom.features.selfhosted.backupServices = [
        "authelia-${instanceName}.service"
        "redis-authelia-${instanceName}.service"
      ];

      services = {
        authelia.instances.${instanceName} = {
          enable = true;
          secrets = with config.sops; {
            jwtSecretFile = secrets."authelia/identity_validation/reset_password/jwt_secret".path;
            oidcIssuerPrivateKeyFile = secrets."authelia/identity_providers/oidc/jwks/key".path;
            oidcHmacSecretFile = secrets."authelia/identity_providers/oidc/hmac_secret".path;
            sessionSecretFile = secrets."authelia/session/secret".path;
            storageEncryptionKeyFile = secrets."authelia/storage/encryption_key".path;
          };
          environmentVariables = {
            X_AUTHELIA_CONFIG_FILTERS = "template";
          };
          settings = {
            server = {
              address = "tcp://:9091";
              buffers = {
                read = 32768;
                write = 32768;
              };
            };
            theme = "dark";
            log.level = "debug";
            totp.issuer = instanceName;
            authentication_backend.file.path = "${stateDir}/users_database.yml";
            access_control = {
              default_policy = "one_factor";
            };
            session = {
              cookies = [
                {
                  name = "sub0_session";
                  domain = instanceName;
                  authelia_url = lib.custom.mkPublicHttpsUrl config.constants "login";
                  inactivity = "1 week";
                  expiration = "3 weeks";
                  remember_me = "1 month";
                }
              ];
              redis = {
                host = "localhost";
                port = redisPort;
              };
            };
            regulation = {
              max_retries = 3;
              find_time = "2 minutes";
              ban_time = "5 minutes";
            };
            storage = {
              local.path = "${stateDir}/db.sqlite3";
            };
            server.endpoints.authz.forward-auth.implementation = "ForwardAuth";
            notifier = {
              disable_startup_check = false;
              filesystem.filename = "${stateDir}/notification.txt";
            };
          }
          // config.custom.features.selfhosted.autheliaExtraConfig;

          settingsFiles = [
            (pkgs.writeText "extra_secrets.yml" ''
              session:
                redis:
                  password: {{ secret "${config.sops.secrets."authelia/session/redis/password".path}" }}
            '')
            (
              let
                allOidcClients = config.custom.features.selfhosted.oidcClients;
                clientList = lib.mapAttrsToList (
                  serviceName: clientConfig:
                  let
                    serviceUrl = lib.custom.mkPublicHttpsUrl config.constants clientConfig.subdomain;
                    domainBasedUris = map (path: "${serviceUrl}${path}") clientConfig.redirects;
                    allRedirectUris = domainBasedUris ++ clientConfig.customRedirects;
                    isPublicClient = clientConfig.extraConfig.public or false;
                    autoFields = {
                      client_id = "{{ secret \"/run/secrets/authelia/identity_providers/oidc/clients/${serviceName}/client_id\" }}";
                      redirect_uris = allRedirectUris;
                    }
                    // (lib.optionalAttrs (!isPublicClient) {
                      client_secret = "{{ secret \"/run/secrets/authelia/identity_providers/oidc/clients/${serviceName}/client_secret\" }}";
                    });
                    finalConfig = clientConfig.extraConfig // autoFields;
                  in
                  finalConfig
                ) allOidcClients;

                clientConfigs = lib.concatStringsSep "\n" (
                  map (
                    client:
                    let
                      coreFields = [
                        "- client_id: ${client.client_id}"
                      ]
                      ++ (lib.optional (client ? client_secret) "  client_secret: ${client.client_secret}")
                      ++ [
                        "  public: ${lib.boolToString (client.public or false)}"
                        "  redirect_uris:"
                      ]
                      ++ (map (uri: "    - \"${uri}\"") client.redirect_uris);

                      extraConfig = removeAttrs client [
                        "client_id"
                        "client_secret"
                        "public"
                        "redirect_uris"
                      ];
                      extraConfigLines = lib.concatLists (
                        lib.mapAttrsToList (
                          key: value:
                          if builtins.isList value then
                            [ "${key}:" ] ++ (map (item: "  - \"${toString item}\"") value)
                          else if builtins.isBool value then
                            [ "${key}: ${lib.boolToString value}" ]
                          else
                            [ "${key}: \"${toString value}\"" ]
                        ) extraConfig
                      );

                      allLines = coreFields ++ (map (line: "  ${line}") extraConfigLines);
                    in
                    lib.concatStringsSep "\n" (map (line: "                        ${line}") allLines)
                  ) clientList
                );
              in
              pkgs.writeText "oidc_clients.yml" ''
                                    identity_providers:
                                      oidc:
                                        clients:
                ${clientConfigs}
              ''
            )
          ];
        };

        redis.servers."authelia-${instanceName}" = {
          enable = true;
          port = redisPort;
          settings = {
            maxmemory = "512mb";
            maxmemory-policy = "allkeys-lru";
            protected-mode = true;
          };
        };
      };

      sops.secrets =
        let
          coreSecretPaths = [
            "authelia/identity_validation/reset_password/jwt_secret"
            "authelia/identity_providers/oidc/jwks/key"
            "authelia/identity_providers/oidc/hmac_secret"
            "authelia/session/secret"
            "authelia/session/redis/password"
            "authelia/storage/encryption_key"
          ];

          allOidcClients = config.custom.features.selfhosted.oidcClients;
          oidcClientSecretPaths = lib.concatLists (
            lib.mapAttrsToList (
              serviceName: clientConfig:
              let
                isPublicClient = clientConfig.extraConfig.public or false;
              in
              [ "authelia/identity_providers/oidc/clients/${serviceName}/client_id" ]
              ++ (lib.optional (
                !isPublicClient
              ) "authelia/identity_providers/oidc/clients/${serviceName}/client_secret")
            ) allOidcClients
          );

          allSecretPaths = coreSecretPaths ++ oidcClientSecretPaths;
        in
        lib.listToAttrs (
          map (
            secretPath:
            lib.nameValuePair secretPath {
              owner = config.services.authelia.instances.${instanceName}.user;
            }
          ) allSecretPaths
        );
    };
}
