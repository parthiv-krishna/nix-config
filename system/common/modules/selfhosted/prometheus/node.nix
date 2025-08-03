{
  config,
  lib,
  ...
}:
let
  # Shared service configuration for all node exporters
  mkNodeExporterService =
    hostName:
    lib.custom.mkSelfHostedService {
      inherit config lib;
      name = "prometheus-node";
      inherit hostName;
      public = false;
      protected = false;
      serviceConfig = {
        services.prometheus.exporters.node = {
          enable = true;
          port = config.constants.ports.prometheus-node;
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
    (mkNodeExporterService "midnight")
    (mkNodeExporterService "nimbus")
    (mkNodeExporterService "vardar")
  ];
}
