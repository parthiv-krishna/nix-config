# Immich - photo storage
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "immich";
  subdomain = "photos";
  port = 2283;
  statusPath = "/api/server/ping";

  # Immich has built-in automatic database backups so we don't need it as a backupService

  homepage = {
    category = "Storage";
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
    {
      services = {
        immich = {
          enable = true;
          host = "0.0.0.0";
          mediaLocation = "/var/lib/immich";
          # Point immich-machine-learning to the cuda-enabled runtime
          machine-learning = {
            enable = true;
            environment = {
              LD_LIBRARY_PATH = "${pkgs.python312Packages.onnxruntime}/lib/python3.12/site-packages/onnxruntime/capi";
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

      # Enable cuda support for onnxruntime
      nixpkgs.overlays = [
        (_: prev: {
          onnxruntime = prev.onnxruntime.override { cudaSupport = true; };
        })
      ];

      # Unfree build requirements for cuda support
      custom.features.meta.unfree.allowedPackages = [
        "cudnn"
        "libcufile"
        "libcusparse_lt"
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
