# Radarr - movie management
{ lib }:
let
  port = 7878;
  stateDir = "/var/lib/media/state/radarr";
in
lib.custom.mkSelfHostedFeature {
  name = "radarr";
  subdomain = "movies";
  inherit port;
  statusPath = "/ping";
  vpn = true;

  backupServices = [ "radarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage movies";
    icon = "sh-radarr";
  };

  serviceConfig = _cfg: _: {
    services.radarr = {
      enable = true;
      user = "radarr";
      group = "media";
      dataDir = stateDir;
      settings = {
        log.analyticsEnabled = false;
        server.port = port;
        update = {
          automatically = false;
          mechanism = "external";
        };
      };
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/media/library 2775 root media - -"
        "d /var/lib/media/library/movies 2775 root media - -"
      ];
      services.radarr.serviceConfig.UMask = lib.mkForce "0002";
    };

    users.users.radarr = {
      isSystemUser = true;
      group = "media";
      uid = 275;
    };
  };
}
