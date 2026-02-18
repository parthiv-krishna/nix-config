{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 9106;
  devices = [
    "/dev/sda"
    "/dev/sdb"
    "/dev/sdc"
    "/dev/nvme0n1"
  ];
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "prometheus-smartmon";
  host = hosts.midnight;
  inherit port;
  serviceConfig = {
    services.prometheus.exporters.smartctl = {
      enable = true;
      inherit port;
      openFirewall = false;
      maxInterval = "60s";
      inherit devices;
    };

    # add necessary capabilities and permissions for NVMe access
    systemd.services.prometheus-smartctl-exporter = {
      serviceConfig = {
        AmbientCapabilities = [ "CAP_SYS_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_SYS_ADMIN" ];
        DeviceAllow = devices;
      };
    };
  };
}
