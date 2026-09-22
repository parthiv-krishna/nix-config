# Forward the systemd journal to the central Loki instance
{ lib }:
lib.custom.mkFeature {
  path = [
    "systemd"
    "alloy"
  ];

  systemConfig =
    _cfg:
    { config, ... }:
    {
      services.alloy = {
        enable = true;
        extraFlags = [ "--disable-reporting" ];
      };

      environment.etc."alloy/loki.alloy".text = ''
        discovery.relabel "journal" {
          targets = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }

          rule {
            source_labels = ["__journal_priority_keyword"]
            target_label  = "level"
          }
        }

        loki.source.journal "systemd" {
          max_age       = "12h"
          relabel_rules = discovery.relabel.journal.rules
          labels = {
            host = "${config.networking.hostName}",
            job  = "systemd-journal",
          }
          forward_to = [loki.write.nimbus.receiver]
        }

        loki.write "nimbus" {
          endpoint {
            url = "${lib.custom.mkInternalHttpsUrl config.constants "logs" "nimbus"}/loki/api/v1/push"
          }
        }
      '';

      systemd.services.alloy = {
        wants = [
          "network-online.target"
          "tailscaled.service"
        ];
        after = [
          "network-online.target"
          "tailscaled.service"
        ];
      };
    };
}
