{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  host = config.constants.hosts.midnight;
  mediaDir = "/var/lib/media";
  stateDir = "/var/lib/media/state";
in
{
  imports = [
    inputs.nixarr.nixosModules.default
    (
      let
        port = 6767;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "bazarr";
        inherit port host;
        homepage = {
          category = config.constants.homepage.categories.media-management;
          description = "Manage subtitles";
          icon = "sh-bazarr";
        };
        subdomain = "subtitles";
        serviceConfig = {
          nixarr.bazarr = {
            enable = true;
            inherit port;
            vpn.enable = true;
          };
        };
      }
    )
    (
      let
        port = 7878;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "radarr";
        inherit host port;
        subdomain = "movies";
        homepage = {
          category = config.constants.homepage.categories.media-management;
          description = "Manage movies";
          icon = "sh-radarr";
        };
        serviceConfig = {
          nixarr.radarr = {
            enable = true;
            inherit port;
            vpn.enable = true;
          };
        };
      }
    )
    (
      let
        port = 8096;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "jellyfin";
        inherit host port;
        subdomain = "tv";
        homepage = {
          category = config.constants.homepage.categories.media;
          description = "Watch movies and TV";
          icon = "sh-jellyfin";
        };
        oidcClient = {
          redirects = [ "/sso/OID/redirect/authelia" ];
          extraConfig = {
            client_name = "Jellyfin";
            scopes = [
              "groups"
              "openid"
              "profile"
            ];
            authorization_policy = "one_factor";
            require_pkce = true;
            pkce_challenge_method = "S256";
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_post";
          };
        };

        serviceConfig = {
          nixarr.jellyfin = {
            enable = true;
            # inherit port;
            # vpn.enable = true;
          };
        };
      }

    )
    (
      let
        port = 5055;
        # OIDC is not in the mainline yet, so we need to use a custom build
        # TODO: remove this once OIDC support is mainlined
        jellyseerrOIDC = pkgs.jellyseerr.overrideAttrs (oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "fallenbagel";
            repo = "jellyseerr";
            rev = "39b6f47c104f9f0356bf51c6cb7e3996f154a8c2";
            hash = "sha256-iBnO0WjNqvXfuJMoS6z/NmYgtW5FQ9Ptp9uV5rODIf8=";
          };
          version = "1.9.2-oidc";

          pnpmDeps = oldAttrs.pnpmDeps.overrideAttrs (_oldDepAttrs: {
            src = pkgs.fetchFromGitHub {
              owner = "fallenbagel";
              repo = "jellyseerr";
              rev = "39b6f47c104f9f0356bf51c6cb7e3996f154a8c2";
              hash = "sha256-iBnO0WjNqvXfuJMoS6z/NmYgtW5FQ9Ptp9uV5rODIf8=";
            };
            outputHash = "sha256-lq/b2PqQHsZmnw91Ad4h1uxZXsPATSLqIdb/t2EsmMI=";
          });
        });
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "jellyseerr";
        inherit host port;
        subdomain = "request";
        serviceConfig = {
          nixarr.jellyseerr = {
            enable = true;
            inherit port;
            package = jellyseerrOIDC;
            # vpn.enable = true;
          };
        };
        homepage = {
          category = config.constants.homepage.categories.media;
          description = "Request media";
          icon = "sh-jellyseerr";
        };
        oidcClient = {
          redirects = [ "/login?provider=sub0.net&callback=true" ];
          # TODO: remove when jellyseerr doesn't force HTTP
          customRedirects = [ "http://request.sub0.net/login?provider=sub0.net&callback=true" ];
          extraConfig = {
            client_name = "Jellyseerr";
            scopes = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            authorization_policy = "one_factor";
            token_endpoint_auth_method = "client_secret_post";
          };
        };
      }
    )
    (
      let
        port = 9696;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "prowlarr";
        inherit host port;
        homepage = {
          category = config.constants.homepage.categories.media-management;
          description = "Manage indexers";
          icon = "sh-prowlarr";
        };
        subdomain = "indexers";
        serviceConfig = {
          nixarr.prowlarr = {
            enable = true;
            inherit port;
            vpn.enable = true;
          };
        };
      }
    )
    (
      let
        port = 8989;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "sonarr";
        inherit host port;
        homepage = {
          category = config.constants.homepage.categories.media-management;
          description = "Manage shows";
          icon = "sh-sonarr";
        };
        subdomain = "shows";
        serviceConfig = {
          nixarr.sonarr = {
            enable = true;
            # doesn't define port
            # inherit port;
            vpn.enable = true;
          };
        };
      }
    )
    (
      let
        port = 9090;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "transmission";
        inherit host port;
        homepage = {
          category = config.constants.homepage.categories.media-management;
          description = "Manage downloads";
          icon = "sh-transmission";
        };
        subdomain = "download";
        serviceConfig = {
          nixarr.transmission = {
            enable = true;
            uiPort = port;
            vpn.enable = true;
            credentialsFile = config.sops.templates.transmission-credentials.path;
            messageLevel = "debug";
          };

          sops = {
            templates.transmission-credentials = {
              owner = "transmission";
              group = "media";
              mode = "0600";
              content = ''
                {
                  "rpc-username": "admin",
                  "rpc-password": "${config.sops.placeholder."media/transmission-password"}",
                  "rpc-authentication-required": true
                }
              '';
            };
            secrets."media/transmission-password" = {
              owner = "transmission";
              group = "media";
              mode = "0600";
            };
          };
        };
      }
    )
    (
      let
        port = 8889;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "unmanic";
        inherit host port;
        homepage = {
          category = config.constants.homepage.categories.media-management;
          description = "Manage transcodes";
          icon = "sh-unmanic";
        };
        subdomain = "transcode";
        serviceConfig =
          let
            transcodeCache = "/var/cache/unmanic";
          in
          {
            virtualisation.oci-containers.containers.unmanic = {
              image = "ghcr.io/unmanic/unmanic:latest";
              ports = [ "${toString port}:8888" ];
              volumes = [
                "${stateDir}/unmanic:/config"
                "${mediaDir}/library:/library"
                "${transcodeCache}:/tmp/unmanic"
              ];
              environment = {
                PUID = toString config.users.users.unmanic.uid;
                PGID = toString config.users.groups.media.gid;
              };
              devices = [
                "/dev/dri"
              ];
            };

            # create tmpfs for transcode cache
            fileSystems.${transcodeCache} = {
              device = "none";
              fsType = "tmpfs";
              options = [
                "size=32G"
                "mode=755"
              ];

            };

            users.users.unmanic = {
              isSystemUser = true;
              group = "media";
              extraGroups = [ "video" ];
            };

            # don't backup the container image
            services.restic.backups.main.exclude = [
              "system/var/lib/containers"
            ];

          };
      }
    )
  ];

  # non-service conmfig
  config =
    lib.mkIf (config.networking.hostName == host.name) {
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
                base_url = "${lib.custom.mkInternalHttpsUrl config.constants "sonarr" host.name}";
                api_key = "!env_var SONARR_API_KEY";
                quality_definition = {
                  type = "series";
                };
                custom_formats = [
                  {
                    trash_ids = [
                      # Unwanted
                      "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
                      "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
                      "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
                      "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                      "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
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
                base_url = "${lib.custom.mkInternalHttpsUrl config.constants "radarr" host.name}";
                api_key = "!env_var RADARR_API_KEY";
                quality_definition = {
                  type = "movie";
                  preferred_ratio = 0.5;
                };
                custom_formats = [
                  {
                    trash_ids = [
                      # HQ Release Groups
                      "ed27ebfef2f323e964fb1f61391bcb35" # HD Bluray Tier 01
                      "c20c8647f2746a1f4c4262b0fbbeeeae" # HD Bluray Tier 02
                      "5608c71bcebba0a5e666223bae8c9227" # HD Bluray Tier 03
                      "c20f169ef63c5f40c2def54abaf4438e" # WEB Tier 01
                      "403816d65392c79236dcb6dd591aeda4" # WEB Tier 02
                      "af94e0fe497124d1f9ce732069ec8c3b" # WEB Tier 03
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
        # fix TLS issues due to post-tunnel IPv6
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

      custom.discord-notifiers = {
        vpn-test.enable = true;
        vpn-refresh.enable = true;
      };

      sops.secrets."media/wg_config" = { };

      # don't backup media
      services.restic.backups.main.exclude = [
        "system/var/lib/media/library"
        "system/var/lib/media/torrents"
      ];

    }
    // lib.custom.mkPersistentSystemDir {
      directory = mediaDir;
      user = "root";
      group = "root";
      mode = "0755";
    };
}
