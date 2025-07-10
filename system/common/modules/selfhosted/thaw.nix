{
  config,
  inputs,
  ...
}:
let
  cfg = config.custom.selfhosted.thaw;
in
{
  imports = [
    inputs.thaw.nixosModules.thaw
  ];

  custom.selfhosted.thaw = {
    enable = true;
    hostName = "vardar";
    public = true;
    protected = true;
    port = 8301;
    config = {
      services.thaw = {
        enable = true;
        inherit (cfg) port;
        machines = {
          midnight = {
            ip = "192.168.4.2";
            mac = "a8:b8:e0:04:4a:57";
            display_name = "Main Server";
            timeout_seconds = 1;
            broadcast_ip = "192.168.4.255";
            wake_port = 9;
          };
        };
      };
    };
  };
}
