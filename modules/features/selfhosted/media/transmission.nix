# Transmission - torrent downloads
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "transmission";
  subdomain = "download";
  port = 9090;

  backupServices = [ "transmission.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage downloads";
    icon = "sh-transmission";
    status = "/transmission/web/";
  };

  serviceConfig =
    _cfg:
    { config, ... }:
    {
      nixarr.transmission = {
        enable = true;
        uiPort = 9090;
        vpn.enable = true;
        credentialsFile = config.sops.templates.transmission-credentials.path;
        messageLevel = "debug";
      };

      sops = {
        templates.transmission-credentials = {
          owner = "transmission";
          group = "media";
          mode = "0600";
          content = ''
            {
              "rpc-username": "admin",
              "rpc-password": "${config.sops.placeholder."media/transmission-password"}",
              "rpc-authentication-required": true
            }
          '';
        };
        secrets."media/transmission-password" = {
          owner = "transmission";
          group = "media";
          mode = "0600";
        };
      };
    };
}
