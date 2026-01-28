{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 3210;
  name = "copyparty";
  subdomain = "drive2";

  # base directory for all copyparty storage
  baseDir = "/var/lib/copyparty";
  usersDir = "${baseDir}/users";
  sharedDir = "${baseDir}/shared";

  fqdn = {
    internal = lib.custom.mkInternalFqdn config.constants subdomain hosts.midnight.name;
    public = lib.custom.mkPublicFqdn config.constants subdomain;
  };
  autheliaUrl = lib.custom.mkPublicHttpsUrl config.constants "login";

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

      reverse_proxy localhost:${toString port}
    '';
  };
in
{
  imports = [ "${inputs.copyparty}/contrib/nixos/modules/copyparty.nix" ];
}
// lib.custom.mkSelfHostedService {
  inherit config lib;
  inherit name;
  host = hosts.midnight;
  inherit port subdomain;
  backupServices = [ "copyparty.service" ];
  homepage = {
    category = config.constants.homepage.categories.storage;
    description = "(BETA) new option for file storage";
    icon = "sh-copyparty";
  };

  persistentDirectories = [
    {
      directory = baseDir;
      user = name;
      group = name;
      mode = "0750";
    }
  ];

  serviceConfig = {
    services.copyparty = {
      enable = true;
      user = name;
      group = name;

      settings = {
        i = "0.0.0.0";
        p = port;
        no-reload = true;

        # idp via authelia headers
        idp-h-usr = "Remote-User";
        idp-h-grp = "Remote-Groups";

        # trust localhost as headers source
        xff-src = "127.0.0.1";

        # persist idp users and groups
        idp-store = 3;

        # indexing and multimedia features
        e2dsa = true;
        e2ts = true;
      };

      volumes = {
        # block access to /users root dir
        "/users" = {
          path = "/dev/null";
          access = {
            r = "@admin";
          };
        };

        # each user gets a private directory at /users/<username>
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

        # shared directory for all users
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

    # ensure storage directories exist
    systemd.tmpfiles.rules = [
      "d ${usersDir} 0755 ${name} ${name} -"
      "d ${sharedDir} 0775 ${name} ${name} -"
    ];

    # override caddy configuration to add forward_auth for authelia integration
    services.caddy.virtualHosts = {
      "${fqdn.internal}" = lib.mkForce (virtualHostConfig fqdn.internal);
      "${fqdn.public}" = lib.mkForce (virtualHostConfig fqdn.public);
    };
  };
}
