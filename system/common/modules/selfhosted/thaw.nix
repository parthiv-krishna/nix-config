{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.thaw.nixosModules.thaw
  ];
}
// (lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "thaw";
  hostName = "vardar";
  public = true;
  protected = true;
  serviceConfig = {
    services.thaw = {
      enable = true;
      port = config.constants.ports.thaw;
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
})
