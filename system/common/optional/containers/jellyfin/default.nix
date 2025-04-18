{ config, helpers, ... }:
let
  name = "jellyfin";
in
{
  imports = [
    (helpers.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  virtualisation.oci-containers.containers."jellyfin-server" = {
    environment = {
      TZ = config.time.timeZone;
    };
  };

  # persist app data
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/jellyfin/config"
      "/var/lib/jellyfin/cache"
    ];
  };
}
