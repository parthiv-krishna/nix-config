{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 9103;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "prometheus-zfs";
  hostName = hosts.midnight;
  inherit port;
  public = false;
  protected = false;
  serviceConfig = {
    services.prometheus.exporters.zfs = {
      enable = true;
      inherit port;
      openFirewall = false;
    };
  };
}
