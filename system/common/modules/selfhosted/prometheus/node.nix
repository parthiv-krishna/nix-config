{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 9101;
  # shared service configuration for all node exporters
  mkNodeExporterService =
    host:
    lib.custom.mkSelfHostedService {
      inherit config lib;
      name = "prometheus-node-${host.name}";
      inherit host;
      inherit port;
      serviceConfig = {
        services.prometheus.exporters.node = {
          enable = true;
          inherit port;
          openFirewall = false;
          enabledCollectors = [
            "cpu"
            "meminfo"
            "filesystem"
            "netdev"
            "loadavg"
          ];
          extraFlags = [
            # exclude virtual filesystems
            "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|run|var/.+|run/.+)($$|/)"
          ];
        };
      };
    };
in
{
  imports = [
    (mkNodeExporterService hosts.midnight)
    (mkNodeExporterService hosts.nimbus)
  ];
}
