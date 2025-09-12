{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.reverse-proxy;
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.caddy = {
          enable = true;
          package = pkgs.caddy.withPlugins {
            # TODO: https://github.com/escherlies/nixos-caddy-with-modules ?
            plugins = [
              "github.com/caddy-dns/cloudflare@v0.2.1"
              "github.com/hslatman/caddy-crowdsec-bouncer@v0.8.1"
            ];
            hash = "sha256-EsIilxpS8pibyrppsYMAxz2CF123YOOEWpd2E4n/hWQ=";
          };
          inherit (cfg) email;
          globalConfig =
            let
              # acme_ca = "https://acme-staging-v02.api.letsencrypt.org/directory";
              acme_ca = "https://acme-v02.api.letsencrypt.org/directory";
            in
            ''
              acme_ca ${acme_ca}
              log stdout_logger {
               output file ${config.services.caddy.logDir}/access.log {
                  roll_size 10MB
                  roll_keep 5
                  roll_keep_for 14d
                  mode 0640
                }
                level INFO
              }
              metrics {
                per_host
              }
              servers {
                max_header_size 5MB
              }
            '';
          # virtualHosts are configured by individual services or other modules (like mkSelfHostedService)
        };

        # enable HTTP/S
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        # Read secrets into environment variables for Caddy
        systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates.caddy-environment.path;

        sops = {
          templates.caddy-environment = {
            content = ''
              CF_API_TOKEN="${config.sops.placeholder.${cfg.cloudflareTokenSecretName}}"
            '';
            owner = config.services.caddy.user;
            inherit (config.services.caddy) group;
          };
          secrets.${cfg.cloudflareTokenSecretName} = {
            owner = config.services.caddy.user;
            inherit (config.services.caddy) group;
          };
        };
      }
      (lib.custom.mkPersistentSystemDir {
        directory = "/var/lib/caddy";
        inherit (config.services.caddy) user group;
        mode = "0755";
      })
    ]
  );
}
