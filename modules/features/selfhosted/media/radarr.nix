# Radarr - movie management
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "radarr";
  subdomain = "movies";
  port = 7878;
  statusPath = "/ping";

  backupServices = [ "radarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage movies";
    icon = "sh-radarr";
  };

  vpn = {
    enable = true;
    namespace = "wg";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/media/state/radarr";
      user = "radarr";
      group = "media";
    }
  ];

  serviceConfig = _cfg: _: {
    services.radarr = {
      enable = true;
      group = "media";
      dataDir = "/var/lib/media/state/radarr";
    };
  };
}
