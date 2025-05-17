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
  options.custom.reverse-proxy = {
    enable = lib.mkEnableOption "Caddy-based reverse proxy";

    publicFacing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this Caddy instance is directly facing the public internet. Enables crowdsec.";
    };

    cloudflareTokenSecretName = lib.mkOption {
      type = lib.types.str;
      default = "caddy/cloudflare_api_token";
      description = "The name of the Sops secret that holds the Cloudflare API token (e.g., 'cloudflare/api_token').";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email address for ACME (Let's Encrypt) certificate registration.";
      example = "admin@example.com";
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/caddy-dns/cloudflare@v0.2.1"
        ];
        hash = "sha256-saKJatiBZ4775IV2C5JLOmZ4BwHKFtRZan94aS5pO90=";
      };
      inherit (cfg) email;
      globalConfig = ''
        acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
        log stdout_logger {
          output stdout
          format console
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
  };
}
