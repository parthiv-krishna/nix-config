{ config, lib, ... }:
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "ollama";
  hostName = "midnight";
  public = false;
  serviceConfig = lib.mkMerge [
    {
      services = {
        ollama = {
          enable = true;
          acceleration = "cuda";
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
