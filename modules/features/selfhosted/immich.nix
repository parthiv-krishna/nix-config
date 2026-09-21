# Immich - photo storage
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "immich";
  subdomain = "photos";
  port = 2283;
  statusPath = "/api/server/ping";

  # Immich has built-in automatic database backups so we don't need it as a backupService

  homepage = categories: {
    category = categories.storage;
    description = "Photo storage";
    icon = "sh-immich";
  };

  oidcClient = {
    redirects = [
      "/auth/login"
      "/user-settings"
    ];
    customRedirects = [ "app.immich:///oauth-callback" ];
    extraConfig = {
      client_name = "Immich";
      scopes = [
        "openid"
        "profile"
        "email"
      ];
      authorization_policy = "one_factor";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_post";
    };
  };

  persistentDirectories = [
    {
      directory = "/var/lib/postgresql";
      user = "postgresql";
      group = "postgresql";
      mode = "0755";
    }
    {
      directory = "/var/lib/redis-immich";
      user = "redis-immich";
      group = "redis-immich";
      mode = "0700";
    }
    {
      directory = "/var/lib/immich";
      user = "immich";
      group = "immich";
      mode = "0700";
    }
  ];

  serviceConfig =
    _cfg:
    { pkgs, ... }:
    let
      # immich machine learning is broken on intel GPU (openVINO)
      # fall back to CPU for now
      immich-machine-learning-cpu = pkgs.immich-machine-learning.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace immich_ml/models/constants.py \
            --replace-fail '    "OpenVINOExecutionProvider",' ""
        '';
        pytestFlagsArray = (old.pytestFlagsArray or [ ]) ++ [
          "--deselect=test_main.py::TestOrtSession::test_sets_openvino_provider_if_available"
        ];
      });
    in
    {
      services = {
        immich = {
          enable = true;
          host = "0.0.0.0";
          mediaLocation = "/var/lib/immich";
          package = pkgs.immich.override {
            "immich-machine-learning" = immich-machine-learning-cpu;
          };
          machine-learning = {
            enable = true;
            environment = {
              MPLCONFIGDIR = "/var/lib/immich/matplotlib";
              HF_HOME = "/var/lib/immich/hf-cache";
              TRANSFORMERS_CACHE = "/var/lib/immich/hf-cache";
            };
          };
          # Allow access to all acceleration devices
          accelerationDevices = null;
        };
      };

      users.users.immich.extraGroups = [
        "video"
        "render"
      ];

      # Don't backup transcoded videos or thumbnails
      custom.features.storage.restic.excludePaths = [
        "/var/lib/immich/encoded-video"
        "/var/lib/immich/thumbs"
        "/var/lib/immich/matplotlib"
        "/var/lib/immich/hf-cache"
      ];
    };
}
