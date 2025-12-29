{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) hosts;
in
lib.custom.mkSelfHostedService {
  inherit
    config
    lib
    ;
  name = "ollama";
  host = hosts.midnight;
  port = 11434;
  persistentDirectories = [ "/var/lib/private/ollama" ];
  serviceConfig = {
    services = {
      ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        # allow remote access (via reverse proxy)
        host = "0.0.0.0";
        models = "/var/lib/ollama";
      };

      # models are very large and not worth backing up
      restic.backups.main.exclude = [ "system/var/lib/private/ollama/blobs" ];

    };
  };

}
