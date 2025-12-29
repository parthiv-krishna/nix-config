{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) hosts;
  subdomain = "auth";
  port = 9091;
  redisPort = 6379;
  instanceName = config.constants.domains.public;
  stateDir = "/var/lib/authelia-${instanceName}";
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "authelia";
  host = hosts.nimbus;
  inherit port subdomain;
  homepage = {
    category = config.constants.homepage.categories.admin;
    description = "Authentication portal";
    icon = "sh-authelia";
  };

  persistentDirectories = [
    {
      directory = stateDir;
      user = "authelia-${instanceName}";
      group = "authelia-${instanceName}";
      mode = "0750";
    }
  ];

  serviceConfig = {
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
          # enable templating filter for secrets
          X_AUTHELIA_CONFIG_FILTERS = "template";
        };
        # initial settings before secret injection
        settings = {
          server = {
            address = "tcp://:${toString port}";
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
                authelia_url = lib.custom.mkPublicHttpsUrl config.constants subdomain;
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
          # see https://www.authelia.com/integration/proxies/caddy/#implementation
          server.endpoints.authz.forward-auth.implementation = "ForwardAuth";
          # TODO: setup SMTP server for email
          notifier = {
            disable_startup_check = false;
            filesystem.filename = "${stateDir}/notification.txt";
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
              # collect all OIDC client configurations from services
              allOidcClients = config.custom.selfhosted.oidcClients;
              # convert configs to YAML, auto-injecting computed fields
              clientList = lib.mapAttrsToList (
                serviceName: clientConfig:
                let
                  # auto-generate redirect URIs from subdomain + paths
                  serviceUrl = lib.custom.mkPublicHttpsUrl config.constants clientConfig.subdomain;
                  domainBasedUris = map (path: "${serviceUrl}${path}") clientConfig.redirects;
                  allRedirectUris = domainBasedUris ++ clientConfig.customRedirects;

                  # auto-generate standard fields
                  autoFields = {
                    # cannot use declarative secrets here as it causes a circular dependency
                    client_id = "{{ secret \"/run/secrets/authelia/identity_providers/oidc/clients/${serviceName}/client_id\" }}";
                    client_secret = "{{ secret \"/run/secrets/authelia/identity_providers/oidc/clients/${serviceName}/client_secret\" }}";
                    public = false;
                    redirect_uris = allRedirectUris;
                  };

                  # merge extraConfig with auto-generated fields (auto fields take precedence)
                  finalConfig = clientConfig.extraConfig // autoFields;
                in
                finalConfig
              ) allOidcClients;

              clientConfigs = lib.concatStringsSep "\n" (
                map (
                  client:
                  let
                    # manually build core fields that need secret interpolation
                    coreFields = [
                      "- client_id: ${client.client_id}" # No quotes for secret interpolation
                      "  client_secret: ${client.client_secret}" # No quotes for secret interpolation
                      "  public: ${lib.boolToString client.public}"
                      "  redirect_uris:"
                    ]
                    ++ (map (uri: "    - \"${uri}\"") client.redirect_uris);

                    # convert extraConfig to proper YAML lines
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

                    # combine core fields with extraConfig, properly indented
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

      # redis server for session storage
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

    # generate all secret declarations
    sops.secrets =
      let
        # Core authelia secrets
        coreSecretPaths = [
          "authelia/identity_validation/reset_password/jwt_secret"
          "authelia/identity_providers/oidc/jwks/key"
          "authelia/identity_providers/oidc/hmac_secret"
          "authelia/session/secret"
          "authelia/session/redis/password"
          "authelia/storage/encryption_key"
        ];

        # OIDC client secrets for all services (authelia needs access to all of them)
        allOidcClients = config.custom.selfhosted.oidcClients;
        oidcClientSecretPaths = lib.concatLists (
          lib.mapAttrsToList (serviceName: _clientConfig: [
            "authelia/identity_providers/oidc/clients/${serviceName}/client_id"
            "authelia/identity_providers/oidc/clients/${serviceName}/client_secret"
          ]) allOidcClients
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
