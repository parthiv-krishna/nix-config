{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) domains;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "homepage";
  hostName = "nimbus";
  subdomain = ""; # on root domain
  public = true;
  protected = true;
  serviceConfig = lib.mkMerge [
    {
      services.homepage-dashboard = {
        enable = true;
        listenPort = config.constants.ports.homepage;
        allowedHosts = domains.public;
        environmentFile = config.sops.templates."homepage/environment".path;

        # TODO: generate names in a better way. move subdomain to constants?
        services = [
          {
            "Media" = [
              {
                "Jellyfin: tv.${domains.public}" = {
                  description = "Movies and TV";
                  href = "https://tv.${domains.public}";
                  icon = "sh-jellyfin";
                  ping = "midnight.${domains.internal}";
                };
              }
            ];
          }
          {
            "Storage" = [
              {
                "Immich: photos.${domains.public}" = {
                  description = "Photo storage";
                  href = "https://photos.${domains.public}";
                  icon = "sh-immich";
                  ping = "midnight.${domains.internal}";
                };
              }
              {
                "OwnCloud: drive.${domains.public}" = {
                  description = "General storage";
                  href = "https://drive.${domains.public}";
                  icon = "sh-owncloud";
                  ping = "midnight.${domains.internal}";
                };
              }
            ];
          }
          {
            "Tools" = [
              {
                "Actual: actual.${domains.public}" = {
                  description = "Budgeting";
                  href = "https://actual.${domains.public}";
                  icon = "sh-actual-budget";
                  ping = "nimbus.${domains.internal}";
                };
              }
              {
                "Mealie: food.${domains.public}" = {
                  description = "Recipies";
                  href = "https://food.${domains.public}";
                  icon = "sh-mealie";
                  ping = "nimbus.${domains.internal}";
                };
              }
            ];
          }
          {
            "Network" = [
              {
                "Thaw: thaw.${domains.public}" = {
                  description = "Wake up sleeping servers";
                  href = "https://thaw.${domains.public}";
                  icon = "mdi-snowflake-melt";
                  ping = "vardar.${domains.internal}";
                };
              }
              {
                "Grafana: stats.${domains.public}" = {
                  description = "Charts and metrics";
                  href = "https://stats.${domains.public}";
                  icon = "sh-grafana";
                  ping = "nimbus.${domains.internal}";
                };
              }
            ];
          }
        ];

        settings = {
          title = "${domains.public} Dashboard";
          description = "${domains.public} Dashboard";
          background = {
            image = "https://images.unsplash.com/photo-1514903936-98502c8f016f?q=80&w=2574&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
            blur = "xs";
            saturate = 50;
            brightness = 50;
            opacity = 50;
          };
          statusStyle = "dot";
          theme = "dark";
          color = "sky";
          hideVersion = true;

        };

        widgets = [
          {
            search = {
              provider = [ "brave" ];
            };
          }
          {
            datetime = {
              text_size = "xl";
              format = {
                timeZone = "US/Pacific";
              };
            };
          }
          {
            openmeteo = {
              label = "Santa Clara, CA";
              latitude = 37.342095;
              longitude = -121.975512;
              units = "imperial";
              timezone = "US/Pacific";
              cache = 5;
            };
          }
        ];
      };

      # add ping to PATH
      # TODO: contribute back to nixpkgs? how?
      systemd.services.homepage-dashboard.path = with pkgs; [
        iputils
      ];

      sops = {
        templates."homepage/environment" = {
          content = ''
            HOMEPAGE_VAR_CROWDSEC_USERNAME="${config.sops.placeholder."homepage/crowdsec_username"}"
            HOMEPAGE_VAR_CROWDSEC_PASSWORD="${config.sops.placeholder."homepage/crowdsec_password"}"
          '';
          mode = "0444";
        };

        secrets = {
          "homepage/crowdsec_username" = { };
          "homepage/crowdsec_password" = { };
        };
      };
    }
  ];
}
