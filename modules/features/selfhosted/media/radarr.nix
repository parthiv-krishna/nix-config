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

  serviceConfig = _cfg: _: {
    nixarr.radarr = {
      enable = true;
      port = 7878;
      vpn.enable = true;
    };
  };
}
