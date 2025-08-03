{
  config,
  lib,
  ...
}:
let
  port = 9101;
  # shared service configuration for all node exporters
  mkNodeExporterService =
    hostName:
    lib.custom.mkSelfHostedService {
      inherit config lib;
      name = "prometheus-node";
      inherit hostName;
      inherit port;
      public = false;
      protected = false;
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
    (mkNodeExporterService "midnight")
    (mkNodeExporterService "nimbus")
  ];
}
