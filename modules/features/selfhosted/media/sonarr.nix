# Sonarr - TV show management
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "sonarr";
  subdomain = "shows";
  port = 8989;

  backupServices = [ "sonarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage shows";
    icon = "sh-sonarr";
    status = "/ping";
  };

  serviceConfig = _cfg: _: {
    nixarr.sonarr = {
      enable = true;
      vpn.enable = true;
    };
  };
}
