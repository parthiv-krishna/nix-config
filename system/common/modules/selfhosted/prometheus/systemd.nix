{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 9105;
  # shared service configuration for systemd exporters
  mkSystemdExporterService =
    host:
    lib.custom.mkSelfHostedService {
      inherit config lib;
      name = "prometheus-systemd-${host.name}";
      inherit host;
      inherit port;
      serviceConfig = {
        services.prometheus.exporters.systemd = {
          enable = true;
          inherit port;
          openFirewall = false;
          # export metrics for all units, including failed and inactive ones
          extraFlags = [
            "--systemd.collector.enable-restart-count"
            "--systemd.collector.enable-ip-accounting"
          ];
        };
      };
    };
in
{
  imports = [
    (mkSystemdExporterService hosts.midnight)
    (mkSystemdExporterService hosts.nimbus)
  ];
}
