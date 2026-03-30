# Selfhosted services base infrastructure
#
# This module provides:
# - Shared options (homepageServices, oidcClients, backupServices) for cross-machine config
# - Caddy reverse proxy base configuration (enabled when enableReverseProxy is set)
{ lib }:
lib.custom.mkFeature {
  path = [ "selfhosted" ];

  extraOptions = {
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
            status = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Health check path (e.g. '/health'). If set, ping will use public FQDN + this path.";
            };
          };
        }
      );
      default = { };
      description = "Metadata for all self-hosted services with homepage entries";
    };

    backupServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of systemd services to stop during backups";
    };

    oidcClients = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            subdomain = lib.mkOption {
              type = lib.types.str;
              description = "Subdomain for the service";
            };
            redirects = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Path segments to append to service URL";
            };
            customRedirects = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Full redirect URIs that don't use the service domain";
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
      description = "OIDC client configurations for Authelia";
    };

    enableReverseProxy = lib.mkEnableOption "selfhosted reverse proxy";

    autheliaExtraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra configuration to merge into Authelia settings";
    };
  };

  systemConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      selfhostedCfg = config.custom.features.selfhosted;
    in
    lib.mkIf selfhostedCfg.enableReverseProxy (
      lib.mkMerge [
        {
          services.caddy = {
            enable = true;
            package = pkgs.caddy.withPlugins {
              plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
              hash = "sha256-7DGnojZvcQBZ6LEjT0e5O9gZgsvEeHlQP9aKaJIs/Zg=";
            };
            email = "letsencrypt.snowy015@passmail.net";
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
              servers {
                max_header_size 5MB
              }
            '';

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
          };

          networking.firewall.allowedTCPPorts = [
            80
            443
          ];

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
