{ config, lib, ... }:
let
  targetHost = "midnight";
in
{
  config = lib.mkIf (config.networking.hostName == targetHost) {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };

    environment.persistence."/persist".directories = lib.mkIf (config.boot.persistence ? "/persist") [
      "/var/lib/jellyfin"
    ];
  };
}
