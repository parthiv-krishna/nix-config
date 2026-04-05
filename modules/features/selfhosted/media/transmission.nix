# Transmission - torrent downloads
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "transmission";
  subdomain = "download";
  port = 9090;
  statusPath = "/transmission/web/";

  backupServices = [ "transmission.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage downloads";
    icon = "sh-transmission";
  };

  vpn = {
    enable = true;
    namespace = "wg";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/media/state/transmission";
      user = "transmission";
      group = "media";
    }
  ];

  serviceConfig =
    _cfg:
    { config, pkgs, ... }:
    {
      services.transmission = {
        enable = true;
        package = pkgs.transmission_4;
        group = "media";
        home = "/var/lib/media/state/transmission";
        downloadDirPermissions = "775";
        credentialsFile = config.sops.templates.transmission-credentials.path;
        settings = {
          rpc-port = 9090;
          rpc-bind-address = "0.0.0.0";
          rpc-whitelist-enabled = false;
          rpc-host-whitelist-enabled = false;
          download-dir = "/var/lib/media/torrents";
          incomplete-dir = "/var/lib/media/torrents/.incomplete";
          incomplete-dir-enabled = true;
          peer-port = 50000;
          message-level = 2; # debug
        };
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
