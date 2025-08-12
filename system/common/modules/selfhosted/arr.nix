{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hostName = config.constants.hosts.midnight;
  mediaDir = "/var/lib/arr/media";
  stateDir = "/var/lib/arr/state";
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
        inherit hostName port;
        subdomain = "subtitles";
        public = false;
        protected = false;
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
        inherit hostName port;
        subdomain = "movies";
        public = false;
        protected = false;
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
        inherit hostName port;
        subdomain = "request";
        public = true;
        protected = true;
        serviceConfig = {
          nixarr.jellyseerr = {
            enable = true;
            inherit port;
            package = jellyseerrOIDC;
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
        inherit hostName port;
        public = false;
        protected = false;
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
        port = 8787;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "readarr";
        inherit hostName port;
        subdomain = "books";
        public = false;
        protected = false;
        serviceConfig = {
          nixarr.readarr = {
            enable = true;
            inherit port;
            vpn.enable = true;
          };
        };
      }
    )
    (
      let
        port = 8080;
      in
      lib.custom.mkSelfHostedService {
        inherit config lib;
        name = "qbittorrent";
        inherit hostName port;
        subdomain = "download";
        public = false;
        protected = false;
        serviceConfig = {
          nixarr.qbittorrent = {
            enable = true;
            uiPort = port;
            vpn.enable = true;
          };

          # fix UID conflict with postgres (on uid 71)
          users.users.qbittorrent = {
            uid = lib.mkForce 2071;
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
        inherit hostName port;
        subdomain = "shows";
        public = false;
        protected = false;
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
  ];

  # non-service conmfig
  config =
    lib.mkIf (config.networking.hostName == hostName) {
      nixarr = {
        enable = true;
        inherit mediaDir stateDir;

        vpn = {
          enable = true;
          wgConf = config.sops.secrets."arr/wg_config".path;
          vpnTestService.enable = true;
        };

        recyclarr = {
          enable = true;
          configuration = {
            sonarr = {
              sonarr_main = {
                base_url = "${lib.custom.mkInternalHttpsUrl config.constants "sonarr" hostName}";
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
                base_url = "${lib.custom.mkInternalHttpsUrl config.constants "radarr" hostName}";
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

      sops.secrets."arr/wg_config" = { };

      # don't backup media
      services.restic.backups.digitalocean.exclude = [
        "system/var/lib/arr/media"
      ];

    }
    // lib.custom.mkPersistentSystemDir {
      directory = mediaDir;
      user = "root";
      group = "root";
      mode = "0755";
    };
}
