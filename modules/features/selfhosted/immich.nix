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
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      # pin to flox-built versions of cuda stuff
      pkgs-flox = import inputs.nixpkgs-flox {
        system = pkgs.stdenv.hostPlatform.system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
          inherit (config.custom.features.hardware.gpu.nvidia) cudaCapability;
        };
      };
      immich-machine-learning-flox = pkgs-flox.immich-machine-learning.override {
        inherit (pkgs) immich;
      };
    in
    {
      services = {
        immich = {
          enable = true;
          host = "0.0.0.0";
          mediaLocation = "/var/lib/immich";
          package = pkgs.immich.override {
            "immich-machine-learning" = immich-machine-learning-flox;
          };
          machine-learning = {
            enable = true;
            environment = {
              LD_LIBRARY_PATH = "${pkgs-flox.python3Packages.onnxruntime}/${pkgs-flox.python3.sitePackages}/onnxruntime/capi";
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
