{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.custom.reverse-proxy;

  pluginName = "notification-http";
  pluginDir = "/var/lib/crowdsec/plugins";

  # build crowdsec notification-http plugin from source
  crowdsecPlugin = pkgs.buildGoModule {
    pname = "crowdsec-${pluginName}";
    version = "1.6.8";
    src = pkgs.fetchFromGitHub {
      owner = "crowdsecurity";
      repo = "crowdsec";
      # TODO: need to keep version in sync with the flake
      # crowdsec is getting added to nixpkgs so we could maybe remove this in the future
      rev = "v1.6.8";
      hash = "sha256-/NTlj0kYCOMxShfoKdmouJTiookDjccUj5HFHLPn5HI=";
    };
    vendorHash = "sha256-7587ezh/9C69UzzQGq3DVGBzNEvTzho/zhRlG6g6tkk=";
    subPackages = [ "cmd/${pluginName}" ];
    ldflags = [
      "-s"
      "-w"
    ];
  };
in
{
  imports = [
    inputs.crowdsec.nixosModules.crowdsec
    inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
  ];
  config = lib.mkIf (cfg.enable && cfg.publicFacing) (
    lib.mkMerge [
      {
        nixpkgs.overlays = [ inputs.crowdsec.overlays.default ];

        # copy plugin binary to pluginDir upon system activation
        system.activationScripts.crowdsec-plugins =
          let
            binPath = "${crowdsecPlugin}/bin/${pluginName}";
          in
          {
            text = ''
              mkdir -p ${pluginDir};
              cp -f ${binPath} ${pluginDir}/${pluginName}
              chown crowdsec:crowdsec ${pluginDir}/${pluginName}
              chmod 0755 ${pluginDir}/${pluginName}
            '';
          };

        services.crowdsec = {
          enable = true;
          allowLocalJournalAccess = true;
          enrollKeyFile = config.sops.secrets."crowdsec/enroll_key".path;
          settings = {
            api.server = {
              listen_uri = "127.0.0.1:${toString config.constants.ports.crowdsec}";
              profiles_path = pkgs.writeText "profiles.yaml" ''
                name: default_ip_remediation
                filters:
                  - Alert.Remediation == true
                decisions:
                  - type: ban
                    scope: Ip
                    duration: 4h
                notifications:
                  - http
              '';
            };
            plugin_config = {
              user = "crowdsec";
              group = "crowdsec";
            };
            prometheus = {
              enabled = true;
              listen_port = config.constants.ports.prometheus-crowdsec;
            };
            config_paths = {
              notification_dir = builtins.dirOf config.sops.templates."crowdsec/notifications/http.yaml".path;
              plugin_dir = pluginDir;
              # allow modification via CLI
              simulation_path = "/var/lib/crowdsec/simulation.yaml";
            };
          };

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
            config.sops.templates."crowdsec/environment".path;
        };

        # ensure crowdsec can access logs
        users.users.crowdsec.extraGroups = [
          "caddy"
          "systemd-journal"
        ];

        # secret management
        sops = {
          templates = {
            "crowdsec/environment".content = ''
              API_KEY=${config.sops.placeholder."crowdsec/firewall_key"}
            '';

            "crowdsec/notifications/http.yaml" = {
              # https://www.spad.uk/posts/integrating-crowdsec-with-traefik-discord/
              content = ''
                type: http
                name: http
                log_level: info
                format: |
                  {
                    "content": null,
                    "embeds": [
                      {{range . -}}
                      {{$alert := . -}}
                      {{range .Decisions -}}
                      {{if $alert.Source.Cn -}}
                      {
                        "title": "{{$alert.MachineID}}: {{.Scenario}}",
                        "description": ":flag_{{ $alert.Source.Cn | lower }}: {{$alert.Source.IP}} will get a {{.Type}} for the next {{.Duration}}. <https://www.shodan.io/host/{{$alert.Source.IP}}>",
                        "url": "https://db-ip.com/{{$alert.Source.IP}}",
                        "color": "16711680"
                      }
                      {{end}}
                      {{if not $alert.Source.Cn -}}
                      {
                        "title": "{{$alert.MachineID}}: {{.Scenario}}",
                        "description": ":pirate_flag: {{$alert.Source.IP}} will get a {{.Type}} for the next {{.Duration}}. <https://www.shodan.io/host/{{$alert.Source.IP}}>",
                        "url": "https://db-ip.com/{{$alert.Source.IP}}",
                        "color": "16711680"
                      }
                      {{end}}
                      {{end -}}
                      {{end -}}
                    ]
                  }
                url: ${config.sops.placeholder."crowdsec/webhook"}
                method: POST
                headers:
                  Content-Type: application/json
              '';
              owner = "crowdsec";
              group = "crowdsec";
              path = "/var/lib/crowdsec/notifications/http.yaml";
            };
          };
          secrets = {
            "crowdsec/enroll_key" = {
              owner = "crowdsec";
              group = "crowdsec";
            };
            "crowdsec/firewall_key" = {
              owner = "crowdsec";
              group = "crowdsec";
            };
            "crowdsec/webhook" = {
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
