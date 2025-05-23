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
      secretTemplate = "{{ secret \"${config.sops.secrets.${fullSecretPath}.path}\" }}";
    in
    {
      sops.secrets.${fullSecretPath} = {
        owner = config.services.authelia.instances.${instance}.user;
        inherit (config.services.authelia.instances.${instance}) group;
      };
      # inject secret into authelia configuration
      services.authelia.instances.${instance}.settings = lib.setAttrByPath attrPath secretTemplate;
    };

  # automatically declare secret and inject into configuration
  mkKeySecret =
    secretPath:
    let
      attrPath = lib.splitString "/" secretPath;
      # path with prefix for lookup in sops file
      fullSecretPath = "authelia/${secretPath}";
      # secret template for authelia configuration
      secretTemplate = "{{ secret \"${
        config.sops.secrets.${fullSecretPath}.path
      }\" | mindent 10 \"|\" | msquote }}";
    in
    {
      sops.secrets.${fullSecretPath} = {
        owner = config.services.authelia.instances.${instance}.user;
        inherit (config.services.authelia.instances.${instance}) group;
      };
      # inject secret into authelia configuration
      services.authelia.instances.${instance}.settings = lib.setAttrByPath attrPath secretTemplate;
    };

  originalAutheliaConfig =
    builtins.foldl' lib.recursiveUpdate
      {
        services.authelia.instances.${instance} = {
          enable = true;
          secrets.manual = true;
          environmentVariables = {
            # enable templating filter for secrets
            X_AUTHELIA_CONFIG_FILTERS = "template";
          };
          # initial settings before secret injection
          settings = import ./settings.nix { };
        };
      }
      [
        # secrets to be injected into authelia configuration
        (mkSecret "identity_validation/reset_password/jwt_secret")
        (mkSecret "session/secret")
        (mkSecret "session/redis/password")
        (mkSecret "storage/encryption_key")
        (mkSecret "identity_providers/oidc/hmac_secret")
        (mkKeySecret "identity_providers/oidc/jwks/main/key")
        (mkSecret "identity_providers/oidc/clients/actual/client_id")
        (mkSecret "identity_providers/oidc/clients/actual/client_secret")
        (mkSecret "identity_providers/oidc/clients/immich/client_id")
        (mkSecret "identity_providers/oidc/clients/immich/client_secret")
        (mkSecret "identity_providers/oidc/clients/jellyfin/client_id")
        (mkSecret "identity_providers/oidc/clients/jellyfin/client_secret")
        # Persistent directory configuration
        (lib.custom.mkPersistentSystemDir { directory = "/var/lib/private/authelia"; })
      ];

  # convert oidc jwks/clients from attribute sets to lists of values
  originalAutheliaSettings = originalAutheliaConfig.services.authelia.instances.${instance}.settings;
  originalOidcSettings = originalAutheliaSettings.identity_providers.oidc;
  transformedOidcSettings = lib.recursiveUpdate originalOidcSettings {
    jwks = lib.attrValues originalOidcSettings.jwks;
    clients = lib.attrValues originalOidcSettings.clients;
  };
  transformedAutheliaSettings = lib.recursiveUpdate originalAutheliaSettings {
    identity_providers = lib.recursiveUpdate originalAutheliaSettings.identity_providers {
      oidc = transformedOidcSettings;
    };
  };
  transformedAutheliaConfig = lib.recursiveUpdate originalAutheliaConfig {
    services.authelia.instances.${instance}.settings = transformedAutheliaSettings;
  };
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "authelia";
  hostName = "vardar";
  public = true;
  serviceConfig = transformedAutheliaConfig;
}
