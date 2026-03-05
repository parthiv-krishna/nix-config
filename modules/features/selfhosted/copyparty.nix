# Copyparty - file storage with IdP integration
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "copyparty";
  subdomain = "drive2";
  port = 3210;

  backupServices = [ "copyparty.service" ];

  homepage = {
    category = "Storage";
    description = "(BETA) new option for file storage";
    icon = "sh-copyparty";
  };

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    let
      name = "copyparty";
      baseDir = "/var/lib/copyparty";
      usersDir = "${baseDir}/users";
      sharedDir = "${baseDir}/shared";
      autheliaUrl = lib.custom.mkPublicHttpsUrl config.constants "login";

      # Custom caddy config with forward_auth for authelia
      virtualHostConfig = logName: {
        logFormat = ''
          output file ${config.services.caddy.logDir}/access-${logName}.log {
            roll_size 10MB
            roll_keep 5
            roll_keep_for 14d
            mode 0640
          }
          level DEBUG
        '';
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
          }

          forward_auth ${autheliaUrl} {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
          }

          reverse_proxy localhost:3210
        '';
      };

      fqdn = {
        internal = lib.custom.mkInternalFqdn config.constants "drive2" config.networking.hostName;
        public = lib.custom.mkPublicFqdn config.constants "drive2";
      };
    in
    {
      # Persistence
      environment.persistence."/persist/system".directories = [
        {
          directory = baseDir;
          user = name;
          group = name;
          mode = "0750";
        }
      ];

      services.copyparty = {
        enable = true;
        user = name;
        group = name;

        settings = {
          i = "0.0.0.0";
          p = 3210;
          no-reload = true;
          idp-h-usr = "Remote-User";
          idp-h-grp = "Remote-Groups";
          xff-src = "127.0.0.1";
          idp-store = 3;
          e2dsa = true;
          e2ts = true;
        };

        volumes = {
          "/users" = {
            path = "/dev/null";
            access = {
              r = "@admin";
            };
          };

          "/users/$\{u\}" = {
            path = "${usersDir}/$\{u\}";
            access = {
              rwmd = "$\{u\}";
              A = "@admin";
            };
            flags = {
              fk = 4;
              scan = 60;
              e2d = true;
              d2t = true;
            };
          };

          "/shared" = {
            path = sharedDir;
            access = {
              r = "*";
              rw = "*";
            };
            flags = {
              fk = 4;
              scan = 60;
              e2d = true;
              d2t = false;
            };
          };
        };

        openFilesLimit = 8192;
      };

      systemd.tmpfiles.rules = [
        "d ${usersDir} 0755 ${name} ${name} -"
        "d ${sharedDir} 0775 ${name} ${name} -"
      ];

      # Override caddy to add forward_auth
      services.caddy.virtualHosts = {
        "${fqdn.internal}" = lib.mkForce (virtualHostConfig fqdn.internal);
        "${fqdn.public}" = lib.mkForce (virtualHostConfig fqdn.public);
      };
    };
}
