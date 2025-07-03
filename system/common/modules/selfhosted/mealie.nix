{ config, lib, ... }:
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "mealie";
  hostName = "nimbus";
  subdomain = "food";
  public = true;
  protected = true;
  serviceConfig = lib.mkMerge [
    {
      services.mealie = {
        enable = true;
        settings = {
          port = config.constants.ports.mealie;
        };
      };
    }
    (lib.custom.mkPersistentSystemDir { directory = "/var/lib/private/mealie"; })
  ];
}
