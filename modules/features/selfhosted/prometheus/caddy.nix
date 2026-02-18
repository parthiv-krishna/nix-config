{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 2019;
  # shared service configuration for caddy metrics exporters
  mkCaddyExporterService =
    host:
    lib.custom.mkSelfHostedService {
      inherit config lib;
      name = "prometheus-caddy-${host.name}";
      inherit host;
      inherit port;
      # mkSelfHostedService automatically creates virtualHosts that reverse proxy to the port
      # so we just need to provide an empty serviceConfig (the admin API runs on port 2019 by default)
      serviceConfig = { };
    };
in
{
  imports = [
    (mkCaddyExporterService hosts.midnight)
    (mkCaddyExporterService hosts.nimbus)
  ];
}
