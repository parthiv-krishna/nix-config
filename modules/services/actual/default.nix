{ config, lib, ... }:
let
  targetHost = "nimbus";
in
{
  config = lib.mkIf (config.networking.hostName == targetHost) (
    {
      services.actual = {
        enable = true;
        settings.port = 5006;
        openFirewall = true;
      };

    }
    // lib.custom.mkPersistentSystemDir { directory = "/var/lib/private/actual"; }
  );
}
