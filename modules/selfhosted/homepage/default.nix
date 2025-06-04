{ config, lib, ... }:
let
  inherit (config.constants) domains;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "homepage";
  hostName = "nimbus";
  subdomain = ""; # on root domain
  public = true;
  protected = true;
  serviceConfig = lib.mkMerge [
    {
      services.homepage-dashboard = {
        enable = true;
        listenPort = config.constants.ports.homepage;
        allowedHosts = domains.public;
      };
    }
  ];
}
