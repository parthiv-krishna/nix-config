{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.reverse-proxy;
in
{
  config = lib.mkIf (cfg.enable && cfg.publicFacing) (
    lib.mkMerge [
      {
        nixpkgs.overlays = [ inputs.crowdsec.overlays.default ];

        services.crowdsec = {
          enable = true;
          allowLocalJournalAccess = true;
          enrollKeyFile = config.sops.secrets."crowdsec/enroll_key".path;
          settings.api.server.listen_uri = "127.0.0.1:${toString config.constants.ports.crowdsec}";
          acquisitions = [
            # monitor Caddy logs
            {
              labels.type = "caddy";
              filenames = [
                "${config.services.caddy.logDir}/access.log"
                "${config.services.caddy.logDir}/access-*.log"
              ];
            }
            # monitor SSH logs
            {
              labels.type = "syslog";
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            }
            # monitor Authelia logs
            {
              labels.type = "syslog";
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=authelia-${cfg.autheliaInstanceName}.service" ];
            }
          ];
        };

        # firewall bouncer for IP blocking
        services.crowdsec-firewall-bouncer = {
          enable = true;
          settings = {
            api_key = "\${API_KEY}";
            api_url = "http://127.0.0.1:${toString config.constants.ports.crowdsec}";
          };
        };

        # pre-start scripts to properly initialize CrowdSec
        systemd.services = {
          crowdsec.serviceConfig.ExecStartPre =
            let
              inherit (lib) getExe;
              inherit (pkgs) writeShellScriptBin;
            in
            [
              # register the firewall bouncer with CrowdSec
              (getExe (
                writeShellScriptBin "register-bouncer" ''
                  set -euo pipefail

                  if ! cscli bouncers list | grep -q "firewall"; then
                      cscli bouncers add "firewall" --key "$(cat ${config.sops.secrets."crowdsec/firewall_key".path})"
                  fi
                ''
              ))

              # install needed collections and parsers
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

                  # For Authelia
                  if ! cscli collections list | grep -q "authelia"; then
                      cscli collections install LePresidente/authelia
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

          crowdsec-firewall-bouncer.serviceConfig.EnvironmentFile =
            config.sops.templates.crowdsec-firewall-bouncer-secrets.path;
        };

        # ensure crowdsec can access logs
        users.users.crowdsec.extraGroups = [
          "caddy"
          "systemd-journal"
        ];

        # secret management
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
      }
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
