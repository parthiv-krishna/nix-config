# Prowlarr - indexer management
{ lib }:
let
  stateDir = "/var/lib/media/state/prowlarr";
in
lib.custom.mkSelfHostedFeature {
  name = "prowlarr";
  subdomain = "indexers";
  port = 9696;
  statusPath = "/ping";

  backupServices = [ "prowlarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage indexers";
    icon = "sh-prowlarr";
  };

  vpn = {
    enable = true;
    namespace = "wg";
  };

  persistentDirectories = [
    {
      directory = stateDir;
      user = "prowlarr";
      group = "prowlarr";
    }
  ];

  serviceConfig = _cfg: _: {
    services.prowlarr = {
      enable = true;
      dataDir = stateDir;
    };

    systemd.services.prowlarr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "prowlarr";
      Group = "prowlarr";
    };

    users.users.prowlarr = {
      isSystemUser = true;
      group = "prowlarr";
    };
    users.groups.prowlarr = { };
  };
}
