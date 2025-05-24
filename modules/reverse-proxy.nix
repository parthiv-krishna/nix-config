{
  config,
  inputs,
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
            hash = "sha256-FIXfNZzOlGquWdQwFz+psfag09KlUZD15024M+WdfSo=";
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
               output file /var/log/caddy/access.log {
                  roll_size 10MB
                  roll_keep 5
                  roll_keep_for 14d
                  mode 0640
                }
                level INFO
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
      (lib.mkIf cfg.publicFacing {
        # Import the crowdsec flake overlay
        nixpkgs.overlays = [ inputs.crowdsec.overlays.default ];

        services.crowdsec = {
          enable = true;
          allowLocalJournalAccess = true;
          enrollKeyFile = config.sops.secrets."crowdsec/enroll_key".path;
          settings.api.server.listen_uri = "127.0.0.1:${toString config.constants.services.crowdsec.port}";
          acquisitions = [
            # Monitor Caddy logs
            {
              labels.type = "caddy";
              filenames = [
                "/var/log/caddy/access.log"
                "/var/log/caddy/access-*.log"
              ];
            }
            # Monitor SSH logs
            {
              labels.type = "syslog";
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=ssh.service" ];
            }
          ];
        };

        # Add firewall bouncer for IP blocking
        services.crowdsec-firewall-bouncer = {
          enable = true;
          settings = {
            api_key = "\${API_KEY}";
            api_url = "http://127.0.0.1:${toString config.constants.services.crowdsec.port}";
          };
        };

        # Pre-start scripts to properly initialize CrowdSec
        systemd.services = {
          crowdsec.serviceConfig.ExecStartPre =
            let
              inherit (lib) getExe;
              inherit (pkgs) writeShellScriptBin;
            in
            [
              # Register the firewall bouncer with CrowdSec
              (getExe (
                writeShellScriptBin "register-bouncer" ''
                  set -euo pipefail

                  if ! cscli bouncers list | grep -q "firewall"; then
                      cscli bouncers add "firewall" --key "$(cat ${config.sops.secrets."crowdsec/firewall_key".path})"
                  fi
                ''
              ))

              # Install needed collections and parsers
              (getExe (
                writeShellScriptBin "install-configurations" ''
                  set -euo pipefail

                  # For Caddy
                  if ! cscli collections list | grep -q "caddy"; then
                      cscli collections install crowdsecurity/caddy
                  fi

                  # For SSH
                  if ! cscli collections list | grep -q "linux"; then
                      cscli collections install crowdsecurity/linux
                  fi

                  # Include SSH successful logins
                  if ! cscli parsers list | grep -q "sshd-success-logs"; then
                      cscli parsers install crowdsecurity/sshd-success-logs
                  fi

                  # Don't block private IPs (prevent lockout)
                  if ! cscli parsers list | grep -q "whitelists"; then
                      cscli parsers install crowdsecurity/whitelists
                  fi
                ''
              ))
            ];

          # Load API key from template
          crowdsec-firewall-bouncer.serviceConfig.EnvironmentFile =
            config.sops.templates.crowdsec-firewall-bouncer-secrets.path;
        };

        # Ensure crowdsec can access logs
        users.users.crowdsec.extraGroups = [
          "caddy"
          "systemd-journal"
        ];

        # Secret management
        sops = {
          templates.crowdsec-firewall-bouncer-secrets.content = ''
            API_KEY=${config.sops.placeholder."crowdsec/firewall_key"}
          '';
          secrets = {
            "crowdsec/enroll_key" = {
              owner = "crowdsec";
              group = "crowdsec";
            };
            "crowdsec/firewall_key" = {
              owner = "crowdsec";
              group = "crowdsec";
            };
          };
        };
      })
      (lib.mkIf cfg.publicFacing (
        lib.custom.mkPersistentSystemDir {
          directory = "/var/lib/crowdsec";
          user = "crowdsec";
          group = "crowdsec";
          mode = "0750";
        }
      ))
    ]
  );
}
