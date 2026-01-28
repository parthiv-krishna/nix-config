{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 9104;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "prometheus-smartmon";
  host = hosts.midnight;
  inherit port;
  serviceConfig = {
    services.prometheus.exporters.smartctl = {
      enable = true;
      inherit port;
      openFirewall = false;
      maxInterval = "60s";
    };
  };
}
