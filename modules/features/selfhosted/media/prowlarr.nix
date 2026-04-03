# Prowlarr - indexer management
{ lib }:
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

  serviceConfig = _cfg: _: {
    nixarr.prowlarr = {
      enable = true;
      port = 9696;
      vpn.enable = true;
    };
  };
}
