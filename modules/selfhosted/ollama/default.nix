{ config, lib, ... }:
let
  name = "ollama";
  subdomain = name;
  hostName = "midnight";
in
lib.custom.mkSelfHostedService {
  inherit
    config
    lib
    name
    subdomain
    hostName
    ;
  public = false;
  serviceConfig = lib.mkMerge [
    {
      services = {
        ollama = {
          enable = true;
          acceleration = "cuda";
          # allow remote access (via reverse proxy)
          host = "0.0.0.0";
        };

        # models are very large and not worth backing up
        restic.backups.digitalocean.exclude = [ "/var/lib/private/ollama/models" ];
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = "/var/lib/private/ollama";
    })
  ];

}
