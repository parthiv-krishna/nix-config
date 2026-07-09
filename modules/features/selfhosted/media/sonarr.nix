# Sonarr - TV show management
{ lib }:
let
  port = 8989;
  stateDir = "/var/lib/media/state/sonarr";
in
lib.custom.mkSelfHostedFeature {
  name = "sonarr";
  subdomain = "shows";
  inherit port;
  statusPath = "/ping";
  vpn = true;

  backupServices = [ "sonarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage shows";
    icon = "sh-sonarr";
  };

  serviceConfig = _cfg: _: {
    services.sonarr = {
      enable = true;
      user = "sonarr";
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
        "d /var/lib/media/library/shows 2775 root media - -"
      ];
      services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
    };

    users.users.sonarr = {
      isSystemUser = true;
      group = "media";
      uid = 274;
    };
  };
}
