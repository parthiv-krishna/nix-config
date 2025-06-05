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
            "Services" = [
              {
                "Media" = [
                  {
                    "Jellyfin: tv.${domains.public}" = {
                      description = "Movies and Shows";
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
                      description = "Photo Storage";
                      href = "https://photos.${domains.public}";
                      icon = "sh-immich";
                      ping = "midnight.${domains.internal}";
                    };
                  }
                ];
              }
              {
                "Productivity" = [
                  {
                    "Actual: actual.${domains.public}" = {
                      description = "Budget App";
                      href = "https://actual.${domains.public}";
                      icon = "sh-actual-budget";
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
                ];
              }
            ];
          }
          {
            "Metrics" =
              let
                mkGlances = machine: metric: {
                  type = "glances";
                  url = "http://${machine}.${domains.internal}:${toString config.constants.ports.glances}";
                  version = 4;
                  inherit metric;
                };
              in
              [
                {
                  "Crowdsec" = {
                    description = "Malicious Traffic Bouncer";
                    icon = "sh-crowdsec";
                    widgets = [
                      {
                        type = "crowdsec";
                        url = "http://localhost:${toString config.constants.ports.crowdsec}";
                        username = "{{HOMEPAGE_VAR_CROWDSEC_USERNAME}}";
                        password = "{{HOMEPAGE_VAR_CROWDSEC_PASSWORD}}";
                      }
                    ];
                  };
                }
                {
                  "Systems" = [
                    {
                      "Nimbus" = {
                        widgets = [
                          (mkGlances "nimbus" "info")
                          (mkGlances "nimbus" "cpu")
                          (mkGlances "nimbus" "memory")
                          (mkGlances "nimbus" "network:enp0s6")
                          (mkGlances "nimbus" "fs:/")
                        ];
                      };
                    }
                    {
                      "Midnight" = {
                        widgets = map (mkGlances "midnight") [
                          "info"
                          "cpu"
                          "memory"
                          "network:enp2s0"
                          "fs:/"
                        ];
                      };
                    }
                    {
                      "Vardar" = {
                        widgets = map (mkGlances "vardar") [
                          "info"
                          "cpu"
                          "memory"
                          "network:enp2s0"
                          "fs:/"
                        ];
                      };
                    }
                  ];
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

          layout = [
            {
              "Services" = {
                style = "row";
                columns = 4;
              };
            }
            {
              "Metrics" = {
                style = "row";
                "Systems" = {
                  style = "row";
                  columns = 3;
                };
              };
            }
          ];
        };

        widgets = [
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
      systemd.services.homepage-dashboard.environment.PATH = lib.mkForce "${lib.makeBinPath [
        pkgs.iputils
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.systemd
      ]}";
      systemd.services.homepage-dashboard.environment.LOG_LEVEL = "debug";

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
