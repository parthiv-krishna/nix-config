# Prometheus blackbox exporter - uptime monitoring for selfhosted services
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus-blackbox";
  port = 9115;
  statusPath = null; # Disable uptime monitoring (infrastructure)

  serviceConfig =
    _cfg:
    { pkgs, ... }:
    let
      blackboxConfig = {
        modules = {
          http_2xx = {
            prober = "http";
            timeout = "10s";
            http = {
              method = "GET";
              valid_status_codes = [ ]; # Default: 2xx
              follow_redirects = true;
              fail_if_ssl = false;
              fail_if_not_ssl = true;
              tls_config.insecure_skip_verify = false;
            };
          };
        };
      };

      configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON blackboxConfig);
    in
    {
      services.prometheus.exporters.blackbox = {
        enable = true;
        port = 9115;
        inherit configFile;
        openFirewall = false;
      };
    };
}
