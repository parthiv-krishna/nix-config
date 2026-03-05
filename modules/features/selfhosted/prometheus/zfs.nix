# Prometheus ZFS exporter
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus-zfs";
  port = 9103;

  serviceConfig = _cfg: _: {
    services.prometheus.exporters.zfs = {
      enable = true;
      port = 9103;
      openFirewall = false;
    };
  };
}
