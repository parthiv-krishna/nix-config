{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.selfhosted;
in
{
  imports = lib.custom.scanPaths ./.;

  options.custom.selfhosted = {
    homepageServices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            category = lib.mkOption {
              type = lib.types.str;
              description = "Category for grouping services";
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = "Description of the service";
            };
            icon = lib.mkOption {
              type = lib.types.str;
              description = "Icon identifier for the service";
            };
            name = lib.mkOption {
              type = lib.types.str;
              description = "Service name";
            };
            subdomain = lib.mkOption {
              type = lib.types.str;
              description = "Subdomain for the service";
            };
            hostName = lib.mkOption {
              type = lib.types.str;
              description = "Host name where service runs";
            };
          };
        }
      );
      default = { };
      description = "Metadata for all self-hosted services with homepage entries";
    };

    oidcClients = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            subdomain = lib.mkOption {
              type = lib.types.str;
              description = "Subdomain for the service (auto-generated from mkSelfHostedService)";
            };
            redirects = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Path segments to append to https://subdomain.domain (required)";
            };
            customRedirects = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Full redirect URIs that don't use the service domain (e.g., app URLs)";
            };
            extraConfig = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Additional OIDC configuration fields";
            };
          };
        }
      );
      default = { };
      description = "OIDC client configurations, auto-generates client_id, client_secret, public, and redirect_uris";
    };

    # gets enabled on all hosts that have selhosted services (by mkSelfHostedService)
    enableReverseProxy = lib.mkEnableOption "selfhosted reverse proxy";
  };

  config = lib.mkIf cfg.enableReverseProxy (
    lib.mkMerge [
      {
        services.caddy = {
          enable = true;
          package = pkgs.caddy.withPlugins {
            # TODO: https://github.com/escherlies/nixos-caddy-with-modules ?
            plugins = [
              "github.com/caddy-dns/cloudflare@v0.2.1"
            ];
            hash = "sha256-Dvifm7rRwFfgXfcYvXcPDNlMaoxKd5h4mHEK6kJ+T4A=";
          };
          email = "letsencrypt.snowy015@passmail.net";

          # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
          acmeCA = "https://acme-v02.api.letsencrypt.org/directory";

          logFormat = ''
            output file ${config.services.caddy.logDir}/access.log {
               roll_size 10MB
               roll_keep 5
               roll_keep_for 14d
               mode 0640
             }
             level INFO
          '';

          globalConfig = ''
            metrics {
              per_host
            }
            servers {
              max_header_size 5MB
            }
          '';

          # wildcard public fqdn
          virtualHosts.${lib.custom.mkPublicFqdn config.constants "*"} = {
            logFormat = ''
              output file ${config.services.caddy.logDir}/access-${lib.custom.mkPublicFqdn config.constants "wildcard_"}.log {
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
              redir ${lib.custom.mkPublicHttpsUrl config.constants ""}
            '';
          };

          # wildcard internal fqdn
          virtualHosts.${lib.custom.mkInternalFqdn config.constants "*" config.networking.hostName} = {
            logFormat = ''
              output file ${config.services.caddy.logDir}/access-${
                lib.custom.mkInternalFqdn config.constants "wildcard_" config.networking.hostName
              }.log {
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
              redir ${lib.custom.mkInternalHttpsUrl config.constants "" config.networking.hostName}
            '';
          };
          # virtualHosts are configured by individual services (e.g. via lib.custom.mkSelfHostedService)
        };

        # enable HTTP/S
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        # Read secrets into environment variables for Caddy
        systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates.caddy-environment.path;

        sops =
          let
            cloudflareTokenSecretName = "caddy/cloudflare_dns_token";
          in
          {
            templates.caddy-environment = {
              content = ''
                CF_API_TOKEN="${config.sops.placeholder.${cloudflareTokenSecretName}}"
              '';
              owner = config.services.caddy.user;
              inherit (config.services.caddy) group;
            };
            secrets.${cloudflareTokenSecretName} = {
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
