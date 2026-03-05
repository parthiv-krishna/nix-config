# Prometheus node exporter - system metrics
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus-node";
  port = 9101;

  serviceConfig = _cfg: _: {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9101;
      openFirewall = false;
      enabledCollectors = [
        "cpu"
        "meminfo"
        "filesystem"
        "netdev"
        "loadavg"
      ];
      extraFlags = [
        "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|run|var/.+|run/.+)($$|/)"
      ];
    };
  };
}
