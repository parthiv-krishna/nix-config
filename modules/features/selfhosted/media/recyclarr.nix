# Recyclarr - synchronize TRaSH Guide profiles to Sonarr and Radarr
{ lib }:
lib.custom.mkFeature {
  path = [
    "selfhosted"
    "recyclarr"
  ];

  systemConfig =
    _cfg:
    { config, ... }:
    let
      vpnNamespace = config.custom.features.networking.vpn.namespace;
      arrAddress = config.vpnNamespaces.${vpnNamespace}.namespaceAddress;
    in
    {
      services.recyclarr = {
        enable = true;
        schedule = "daily";
        configuration = {
          sonarr.series = {
            base_url = "http://${arrAddress}:8989";
            api_key._secret = config.sops.secrets."sonarr/api_key".path;
            delete_old_custom_formats = false;

            quality_definition.type = "series";
            quality_profiles = [
              {
                trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
                reset_unmatched_scores.enabled = false;
              }
            ];

            custom_format_groups.add = [
              {
                trash_id = "59c3af66780d08332fdc64e68297098f"; # Unwanted Formats
                exclude = [
                  "15a05bc7c1a36e2b57fd628f8977e2fc" # Allow AV1
                ];
              }
            ];

            custom_formats = [
              {
                trash_ids = [
                  "c9eafd50846d299b862ca9bb6ea91950" # x265
                ];
                assign_scores_to = [
                  {
                    name = "WEB-1080p";
                    score = 50;
                  }
                ];
              }
              {
                trash_ids = [
                  "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                ];
                assign_scores_to = [
                  {
                    name = "WEB-1080p";
                    score = 0;
                  }
                ];
              }
            ];
          };

          radarr.movies = {
            base_url = "http://${arrAddress}:7878";
            api_key._secret = config.sops.secrets."radarr/api_key".path;
            delete_old_custom_formats = false;

            quality_definition.type = "movie";
            quality_profiles = [
              {
                trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
                reset_unmatched_scores.enabled = false;
              }
            ];

            custom_format_groups.add = [
              {
                trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; # Unwanted Formats
                exclude = [
                  "cae4ca30163749b891686f95532519bd" # Allow AV1
                ];
              }
            ];

            custom_formats = [
              {
                trash_ids = [
                  "9170d55c319f4fe40da8711ba9d8050d" # x265
                ];
                assign_scores_to = [
                  {
                    name = "HD Bluray + WEB";
                    score = 50;
                  }
                ];
              }
              {
                trash_ids = [
                  "dc98083864ea246d05a42df0d05f81cc" # x265 (HD)
                ];
                assign_scores_to = [
                  {
                    name = "HD Bluray + WEB";
                    score = 0;
                  }
                ];
              }
            ];
          };
        };
      };

      systemd.services.recyclarr = {
        after = [
          "network-online.target"
          "radarr.service"
          "sonarr.service"
          "vpn.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          StateDirectoryMode = "0700";
          UMask = "0077";
        };
      };

      sops.secrets = {
        "radarr/api_key" = { };
        "sonarr/api_key" = { };
      };
    };
}
