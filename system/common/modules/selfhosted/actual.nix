{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  port = 5006;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "actual";
  hostName = hosts.nimbus;
  inherit port;
  public = true;
  protected = false;
  persistentDirectories = [ "/var/lib/private/actual" ];
  serviceConfig = {
    services.actual = {
      enable = true;
      settings = {
        inherit port;
      };
    };
  };
}
