{
  config,
  lib,
  ...
}:
let
  name = "immich";
  secretName = "${config.networking.hostName}/${name}/environment";
  secretNamePostgres = "${config.networking.hostName}/${name}/environment_postgres";
  dbUsername = "postgres";
  dbDatabaseName = "immich";
in
{
  imports = [
    (lib.custom.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  virtualisation.oci-containers.containers = {
    "immich_server" = {
      environmentFiles = [
        config.sops.secrets."${secretName}".path
      ];
      environment = {
        DB_USERNAME = dbUsername;
        DB_DATABASE_NAME = dbDatabaseName;
      };
    };
    "immich_machine_learning" = {
      environmentFiles = [
        config.sops.secrets."${secretName}".path
      ];
      environment = {
        DB_USERNAME = dbUsername;
        DB_DATABASE_NAME = dbDatabaseName;
      };
    };
    "immich_postgres" = {
      environmentFiles = [
        config.sops.secrets."${secretNamePostgres}".path
      ];
      environment = {
        POSTGRES_USER = dbUsername;
        POSTGRES_DB = dbDatabaseName;
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
    };
  };

  sops.secrets."${secretName}" = { };
  sops.secrets."${secretNamePostgres}" = { };

  # persist app data
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/immich/ml"
      "/var/lib/immich/db"
    ];
  };
}
