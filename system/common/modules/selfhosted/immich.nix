{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) hosts;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "immich";
  hostName = hosts.midnight;
  port = 2283;
  subdomain = "photos";
  public = true;
  protected = false;
  homepage = {
    category = config.constants.homepage.categories.storage;
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
  serviceConfig = {
    services = {
      immich = {
        enable = true;
        host = "0.0.0.0";
        mediaLocation = "/var/lib/immich";
        # point immich-machine-learning to the cuda-enabled runtime (see below)
        machine-learning = {
          enable = true;
          environment = {
            LD_LIBRARY_PATH = "${pkgs.python312Packages.onnxruntime}/lib/python3.12/site-packages/onnxruntime/capi";
            MPLCONFIGDIR = "/var/lib/immich/matplotlib";
          };
        };
        # allow access to all acceleration devices
        accelerationDevices = null;
      };

    };

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];

    # https://discourse.nixos.org/t/immich-and-cuda-accelerated-machine-learning/58330/2
    # enable cuda support for onnxruntime
    nixpkgs.overlays = [
      (_: prev: {
        onnxruntime = prev.onnxruntime.override { cudaSupport = true; };
      })
    ];

    # unfree build requirements for cuda support
    unfree.allowedPackages = [
      "cudnn"
      "libcufile"
      "libcusparse_lt"
    ];

    # don't backup transcoded videos or thumbnails
    services.restic.backups.digitalocean.exclude = [
      "system/var/lib/immich/encoded-video"
      "system/var/lib/immich/thumbs"
    ];

  };
}
