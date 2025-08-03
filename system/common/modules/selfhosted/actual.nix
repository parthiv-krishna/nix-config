{ config, lib, ... }:
let
  port = 5006;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "actual";
  hostName = "nimbus";
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
