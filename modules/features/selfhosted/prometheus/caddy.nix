# Prometheus Caddy metrics exporter
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus-caddy";
  port = 2019;

  # Caddy admin API runs on port 2019 by default
  # mkSelfHostedFeature automatically creates virtualHosts that reverse proxy to the port
  serviceConfig =
    _cfg:
    { config, lib, ... }:
    let
      adminPort = toString 2019;
      publicFqdn = lib.custom.mkPublicFqdn config.constants "prometheus-caddy";
      internalFqdn =
        lib.custom.mkInternalFqdn config.constants "prometheus-caddy"
          config.networking.hostName;
    in
    {
      services.caddy.globalConfig = ''
        admin 127.0.0.1:${adminPort} {
          origins ${publicFqdn} ${internalFqdn} localhost:${adminPort} 127.0.0.1:${adminPort} [::1]:${adminPort}
        }
        metrics {
          per_host
        }
      '';
    };
}
