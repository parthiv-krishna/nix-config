{
  config,
  helpers,
  ...
}:
let
  name = "authelia";
  secretName = "${config.networking.hostName}/containerEnvironments/${name}";
in
{
  imports = [
    (helpers.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  virtualisation.oci-containers.containers."authelia-authelia" = {
    environmentFiles = [
      config.sops.secrets."${secretName}".path
    ];

    environment = {
      TZ = config.time.timeZone;
    };

  };

  virtualisation.oci-containers.containers."authelia-redis" = {
    environmentFiles = [
      config.sops.secrets."${secretName}".path
    ];

    environment = {
      TZ = config.time.timeZone;
    };

  };

  sops.secrets."${secretName}" = { };

  # persist user configuration and redis data
  environment.persistence."/persist/system" = {
    directories = [
      "/var/log/authelia"
      "/var/lib/authelia"
      "/var/lib/authelia-redis"
    ];
  };

}
