# Sonarr - TV show management
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "sonarr";
  subdomain = "shows";
  port = 8989;
  statusPath = "/ping";

  backupServices = [ "sonarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage shows";
    icon = "sh-sonarr";
  };

  vpn = {
    enable = true;
    namespace = "wg";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/media/state/sonarr";
      user = "sonarr";
      group = "media";
    }
  ];

  serviceConfig = _cfg: _: {
    services.sonarr = {
      enable = true;
      group = "media";
      dataDir = "/var/lib/media/state/sonarr";
    };
  };
}
