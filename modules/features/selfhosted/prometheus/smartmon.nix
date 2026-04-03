# Prometheus SMART exporter - disk health metrics
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus-smartmon";
  port = 9106;
  statusPath = null; # Disable uptime monitoring (infrastructure)

  extraOptions = {
    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/dev/sda"
        "/dev/sdb"
        "/dev/sdc"
        "/dev/nvme0n1"
      ];
      description = "Devices to monitor with smartctl";
    };
  };

  serviceConfig = cfg: _: {
    services.prometheus.exporters.smartctl = {
      enable = true;
      port = 9106;
      openFirewall = false;
      maxInterval = "60s";
      inherit (cfg) devices;
    };

    systemd.services.prometheus-smartctl-exporter = {
      serviceConfig = {
        AmbientCapabilities = [ "CAP_SYS_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_SYS_ADMIN" ];
        DeviceAllow = cfg.devices;
      };
    };
  };
}
