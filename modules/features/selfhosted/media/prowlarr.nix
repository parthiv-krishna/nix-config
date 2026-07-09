# Prowlarr - indexer management
{ lib }:
let
  port = 9696;
  stateDir = "/var/lib/media/state/prowlarr";
in
lib.custom.mkSelfHostedFeature {
  name = "prowlarr";
  subdomain = "indexers";
  inherit port;
  statusPath = "/ping";
  vpn = true;

  backupServices = [ "prowlarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage indexers";
    icon = "sh-prowlarr";
  };

  serviceConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.prowlarr = {
        enable = true;
        settings = {
          log.analyticsEnabled = false;
          server.port = port;
          update = {
            automatically = false;
            mechanism = "external";
          };
        };
      };

      systemd = {
        tmpfiles.rules = [
          "d ${stateDir} 0750 prowlarr prowlarr - -"
        ];

        services.prowlarr = {
          unitConfig.RequiresMountsFor = [ stateDir ];
          serviceConfig = {
            DynamicUser = lib.mkForce false;
            ExecStart = lib.mkForce "${lib.getExe config.services.prowlarr.package} -nobrowser -data=${stateDir}";
            ExecStartPre = "+${pkgs.coreutils}/bin/chown -R prowlarr:prowlarr ${stateDir}";
            User = "prowlarr";
            Group = "prowlarr";
            ReadWritePaths = [ stateDir ];
          };
        };
      };

      users = {
        groups.prowlarr.gid = 287;
        users.prowlarr = {
          isSystemUser = true;
          group = "prowlarr";
          uid = 293;
        };
      };
    };
}
