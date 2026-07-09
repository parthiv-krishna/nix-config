# Bazarr - subtitle management
{ lib }:
let
  port = 6767;
  stateDir = "/var/lib/media/state/bazarr";
in
lib.custom.mkSelfHostedFeature {
  name = "bazarr";
  subdomain = "subtitles";
  inherit port;
  statusPath = "/ping";
  vpn = true;

  backupServices = [ "bazarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage subtitles";
    icon = "sh-bazarr";
  };

  serviceConfig = _cfg: _: {
    services.bazarr = {
      enable = true;
      user = "bazarr";
      group = "media";
      dataDir = stateDir;
      listenPort = port;
    };

    systemd.services.bazarr.serviceConfig.UMask = lib.mkForce "0002";

    users.users.bazarr = {
      isSystemUser = true;
      group = "media";
      uid = 232;
    };
  };
}
