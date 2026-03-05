# Prometheus systemd exporter
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus-systemd";
  port = 9105;

  serviceConfig = _cfg: _: {
    services.prometheus.exporters.systemd = {
      enable = true;
      port = 9105;
      openFirewall = false;
      extraFlags = [
        "--systemd.collector.enable-restart-count"
        "--systemd.collector.enable-ip-accounting"
      ];
    };
  };
}
