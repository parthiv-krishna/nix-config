{
  config,
  pkgs,
  ...
}:
let
  inherit (config.constants) tieredCache;
in
{
  custom.selfhosted.immich = {
    enable = true;
    hostName = "midnight";
    subdomain = "photos";
    public = true;
    protected = false;
    port = 2283;
    config = {
      services = {
        immich = {
          enable = true;
          host = "0.0.0.0";
          mediaLocation = "${tieredCache.cachePool}/immich";
          # point immich-machine-learning to the cuda-enabled runtime (see below)
          machine-learning = {
            enable = true;
            environment = {
              LD_LIBRARY_PATH = "${pkgs.python312Packages.onnxruntime}/lib/python3.12/site-packages/onnxruntime/capi";
              MPLCONFIGDIR = "${tieredCache.cachePool}/immich/matplotlib";
            };
          };
          # allow access to all acceleration devices
          accelerationDevices = null;
        };

        # don't backup transcoded videos or thumbnails
        restic.backups.digitalocean.exclude = [
          "${tieredCache.basePool}/immich/encoded-video"
          "${tieredCache.basePool}/immich/thumbs"
        ];
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
    };
    persistentDirs = [
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
    ];
  };
}
