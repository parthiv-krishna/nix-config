{
  config,
  ...
}:
let
  dataDir = "/var/lib/traefik";
  userAndGroupName = "traefik";
in
{
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      # enable traefik dashboard
      api.dashboard = true;

      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          http.tls = {
            certResolver = "letsencrypt";
            domains = [
              {
                # wildcard, one cert works for all subdomains
                main = "sub0.net";
                sans = [ "*.sub0.net" ];
              }
            ];
          };
        };
      };

      certificatesResolvers = {
        letsencrypt = {
          acme = {
            email = "letsencrypt.snowy015@passmail.net";
            storage = "${dataDir}/acme.json";
            # main server (trusted by browsers) - use once it's working on staging
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            # staging server (not trusted by browsers) - use for testing
            # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
            dnsChallenge = {
              provider = "cloudflare";
              resolvers = [
                "1.1.1.1:53"
                "1.0.0.1:53"
              ];
              # wait 60s for TXT records to propagate
              propagation.delayBeforeChecks = 60;
            };
          };
        };
      };
      log = {
        level = "WARN";
        filePath = "${dataDir}/traefik.log";
      };
      accessLog = {
        filePath = "${dataDir}/access.log";
      };
    };
    # each container should define something similar
    dynamicConfigOptions = {
      http = {
        routers.traefik = {
          # traefik dashboard
          rule = "Host(`traefik.sub0.net`)";
          service = "api@internal";
          entrypoints = [ "websecure" ];
        };
      };
    };
  };

  # create service user/group
  users.groups.traefik = { };
  users.users.traefik.extraGroups = [ userAndGroupName ];

  systemd.services.traefik = {
    # pass cloudflare token to the service
    environment = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets."cloudflare/api_token".path;
    };

    # assign service user/group
    serviceConfig = {
      User = userAndGroupName;
      Group = userAndGroupName;
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # HTTP
    443 # HTTPS
  ];

  # persist logs and ACME cert
  environment.persistence."/persist/system" = {
    directories = [
      dataDir
    ];
  };

  # allow service group to read token
  sops.secrets = {
    "cloudflare/api_token" = {
      owner = "root";
      group = userAndGroupName;
      mode = "0640"; # root rw, traefik r
      restartUnits = [ "traefik.service" ];
    };
  };
}
