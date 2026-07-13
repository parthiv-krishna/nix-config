# Transmission - torrent downloads
{ lib }:
let
  port = 9090;
  peerPort = 51413;
  stateDir = "/var/lib/media/state/transmission";
  torrentDir = "/var/lib/media/torrents";
in
lib.custom.mkSelfHostedFeature {
  name = "transmission";
  subdomain = "download";
  inherit port;
  statusPath = "/transmission/web/";
  vpn = true;

  backupServices = [ "transmission.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage downloads";
    icon = "sh-transmission";
  };

  serviceConfig =
    _cfg:
    { config, pkgs, ... }:
    {
      services.transmission = {
        enable = true;
        package = pkgs.transmission_4;
        user = "transmission";
        group = "media";
        home = stateDir;
        credentialsFile = config.sops.templates.transmission-credentials.path;
        openPeerPorts = false;
        openRPCPort = false;
        settings = {
          download-dir = torrentDir;
          incomplete-dir-enabled = true;
          incomplete-dir = "${torrentDir}/.incomplete";
          watch-dir-enabled = true;
          watch-dir = "${torrentDir}/.watch";

          umask = "002";

          rpc-bind-address = "192.168.15.1";
          rpc-port = port;
          rpc-whitelist-enabled = true;
          rpc-whitelist = "127.0.0.1,192.168.*,10.*";

          blocklist-enabled = true;
          blocklist-url = "https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz";

          peer-port = peerPort;
          dht-enabled = true;
          pex-enabled = true;
          utp-enabled = false;
          encryption = 1;
          port-forwarding-enabled = false;

          anti-brute-force-enabled = true;
          anti-brute-force-threshold = 10;

          message-level = 5;
        };
      };

      systemd = {
        tmpfiles.rules = [
          "d ${stateDir} 0750 transmission media - -"
          "d ${stateDir}/.config 0750 transmission media - -"
          "d ${stateDir}/.config/transmission-daemon 0750 transmission media - -"
          "d ${torrentDir} 0755 transmission media - -"
          "d ${torrentDir}/.incomplete 0755 transmission media - -"
          "d ${torrentDir}/.watch 0755 transmission media - -"
          "d ${torrentDir}/manual 0755 transmission media - -"
          "d ${torrentDir}/radarr 0755 transmission media - -"
          "d ${torrentDir}/sonarr 0755 transmission media - -"
          "d ${torrentDir}/shelfmark 0755 transmission media - -"
        ];
        services.transmission.serviceConfig = {
          IOSchedulingPriority = 7;
          UMask = lib.mkForce "0066";
        };
      };

      users.users.transmission = {
        isSystemUser = true;
        description = "Transmission BitTorrent user";
        group = "media";
        uid = 70;
      };

      sops = {
        templates.transmission-credentials = {
          owner = "transmission";
          group = "media";
          mode = "0600";
          content = ''
            {
              "rpc-username": "admin",
              "rpc-password": "${config.sops.placeholder."transmission/password"}",
              "rpc-authentication-required": true
            }
          '';
        };
        secrets."transmission/password" = {
          owner = "transmission";
          group = "media";
          mode = "0600";
        };
      };
    };
}
