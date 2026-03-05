# Media base - shared nixarr config, VPN, recyclarr
{ lib }:
let
  mediaDir = "/var/lib/media";
  stateDir = "/var/lib/media/state";
in
lib.custom.mkFeature {
  path = [
    "selfhosted"
    "media-base"
  ];

  systemConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment.persistence."/persist/system".directories = [
        {
          directory = mediaDir;
          user = "root";
          group = "root";
          mode = "0755";
        }
      ];

      nixarr = {
        enable = true;
        inherit mediaDir stateDir;

        vpn = {
          enable = true;
          wgConf = config.sops.secrets."media/wg_config".path;
        };

        recyclarr = {
          enable = true;
          configuration = {
            sonarr = {
              sonarr_main = {
                base_url = "${lib.custom.mkInternalHttpsUrl config.constants "sonarr" config.networking.hostName}";
                api_key = "!env_var SONARR_API_KEY";
                quality_definition = {
                  type = "series";
                };
                custom_formats = [
                  {
                    trash_ids = [
                      "85c61753df5da1fb2aab6f2a47426b09"
                      "9c11cd3f07101cdba90a2d81cf0e56b4"
                      "e2315f990da2e2cbfc9fa5b7a6fcfe48"
                      "47435ece6b99a0b477caf360e79ba0bb"
                      "fbcb31d8dabd2a319072b84fc0b7249c"
                    ];
                    assign_scores_to = [
                      {
                        name = "WEB-1080p";
                      }
                    ];
                  }
                ];
              };
            };
            radarr = {
              radarr_main = {
                base_url = "${lib.custom.mkInternalHttpsUrl config.constants "radarr" config.networking.hostName}";
                api_key = "!env_var RADARR_API_KEY";
                quality_definition = {
                  type = "movie";
                  preferred_ratio = 0.5;
                };
                custom_formats = [
                  {
                    trash_ids = [
                      "ed27ebfef2f323e964fb1f61391bcb35"
                      "c20c8647f2746a1f4c4262b0fbbeeeae"
                      "5608c71bcebba0a5e666223bae8c9227"
                      "c20f169ef63c5f40c2def54abaf4438e"
                      "403816d65392c79236dcb6dd591aeda4"
                      "af94e0fe497124d1f9ce732069ec8c3b"
                    ];
                    assign_scores_to = [
                      {
                        name = "HD";
                      }
                    ];
                  }
                ];
              };
            };
          };
        };
      };

      systemd = {
        services.wg.serviceConfig.ExecStartPost =
          let
            ip = "${pkgs.iproute2}/bin/ip";
          in
          "${ip} netns exec wg ${ip} link set wg0 mtu 1280";

        services = {
          vpn-test =
            let
              vpnTestScript = pkgs.writeShellApplication {
                name = "vpn-test";
                runtimeInputs = with pkgs; [
                  bash
                  curl
                  iproute2
                  unixtools.ping
                ];
                text = ''
                  echo "Current wireguard interface config:"
                  ip link show wg0

                  echo "Current public IP:"
                  curl -s ifconfig.me

                  echo "Running DNS leak test:"
                  bash ${lib.custom.relativeToRoot "scripts/dnsleaktest.sh"}
                '';
              };
            in
            {
              description = "Test wireguard";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${vpnTestScript}/bin/vpn-test";
              };
              onFailure = [ "vpn-refresh.service" ];
              vpnConfinement = {
                enable = true;
                vpnNamespace = "wg";
              };
            };

          vpn-refresh = {
            description = "Refresh Wireguard";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "systemctl restart wg.service prowlarr.service radarr.service sonarr.service transmission.service";
              ExecStartPost = "systemctl start vpn-test.service";
            };
          };
        };

        timers.vpn-refresh = {
          description = "Refresh wireguard every 3h";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnUnitActiveSec = "3h";
            Unit = "vpn-refresh.service";
          };
        };
      };

      custom.features.meta.discord-notifiers.notifiers = {
        vpn-test.enable = true;
        vpn-refresh.enable = true;
      };

      sops.secrets."media/wg_config" = { };

      services.restic.backups.main.exclude = [
        "system/var/lib/media/library"
        "system/var/lib/media/torrents"
      ];
    };
}
