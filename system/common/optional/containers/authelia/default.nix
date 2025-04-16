{
  config,
  helpers,
  ...
}:
let
  name = "authelia";
  # dummy to find path to secrets
  secrets = "${config.networking.hostName}/${name}";
  # rootSecret is a workaround to determine the actual path of secrets
  # TODO: is there a better way to do this?
  rootSecret = "${secrets}/root";
  secretsDir = builtins.dirOf "${config.sops.secrets.${rootSecret}.path}";
in
{
  imports = [
    (helpers.mkCompose {
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
    "${secrets}/identity_validation/reset_password/jwt_secret" = { };
    "${secrets}/session/secret" = { };
    "${secrets}/session/redis/password" = { };
    "${secrets}/storage/encryption_key" = { };
    "${secrets}/identity_providers/oidc/hmac_secret" = { };
    "${secrets}/identity_providers/oidc/jwks/key" = { };
    "${secrets}/identity_providers/oidc/clients/actual/id" = { };
    "${secrets}/identity_providers/oidc/clients/actual/secret" = { };
    "${secrets}/identity_providers/oidc/clients/jellyfin/id" = { };
    "${secrets}/identity_providers/oidc/clients/jellyfin/secret" = { };
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
