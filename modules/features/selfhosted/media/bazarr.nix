# Bazarr - subtitle management
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "bazarr";
  subdomain = "subtitles";
  port = 6767;
  statusPath = "/ping";

  backupServices = [ "bazarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage subtitles";
    icon = "sh-bazarr";
  };

  serviceConfig = _cfg: _: {
    nixarr.bazarr = {
      enable = true;
      port = 6767;
      vpn.enable = true;
    };
  };
}
