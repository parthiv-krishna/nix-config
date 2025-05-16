{
  config,
  lib,
  ...
}:
let
  name = "authelia";
  # rootSecret is a workaround to determine the actual path of secrets
  # TODO: is there a better way to do this?
  rootSecret = "${name}/root";
  secretsDir = builtins.dirOf "${config.sops.secrets.${rootSecret}.path}";
in
{
  imports = [
    (lib.custom.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  virtualisation.oci-containers.containers."authelia-authelia" = {
    volumes = [
      # extra mount of secrets volume
      "${secretsDir}:/secrets:ro"
    ];

    environment = {
      TZ = config.time.timeZone;
    };

  };

  virtualisation.oci-containers.containers."authelia-redis" = {
    environment = {
      TZ = config.time.timeZone;
    };

  };

  sops.secrets = {
    "${rootSecret}" = { };
    # declare all secrets used in authelia.yml
    "${name}/identity_validation/reset_password/jwt_secret" = { };
    "${name}/session/secret" = { };
    "${name}/session/redis/password" = { };
    "${name}/storage/encryption_key" = { };
    "${name}/identity_providers/oidc/hmac_secret" = { };
    "${name}/identity_providers/oidc/jwks/key" = { };
    "${name}/identity_providers/oidc/clients/actual/id" = { };
    "${name}/identity_providers/oidc/clients/actual/secret" = { };
    "${name}/identity_providers/oidc/clients/immich/id" = { };
    "${name}/identity_providers/oidc/clients/immich/secret" = { };
    "${name}/identity_providers/oidc/clients/jellyfin/id" = { };
    "${name}/identity_providers/oidc/clients/jellyfin/secret" = { };
  };

  # persist user configuration and redis data
  environment.persistence."/persist/system" = {
    directories = [
      "/var/log/authelia"
      "/var/lib/authelia"
      "/var/lib/authelia-redis"
    ];
  };

}
