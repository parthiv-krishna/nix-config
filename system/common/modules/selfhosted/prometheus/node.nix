{
  config,
  ...
}:
{
  custom.selfhosted.prometheus-node = {
    enable = true;
    hostNames = [
      "midnight"
      "nimbus"
      "vardar"
    ];
    public = false;
    protected = false;
    port = 9101;
    config = {
      services.prometheus.exporters.node = {
        enable = true;
        inherit (config.custom.selfhosted.prometheus-node) port;
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
}
