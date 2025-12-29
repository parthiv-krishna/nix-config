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
  host = hosts.midnight;
  inherit port;
  serviceConfig = {
    services.prometheus.exporters.zfs = {
      enable = true;
      inherit port;
      openFirewall = false;
    };
  };
}
