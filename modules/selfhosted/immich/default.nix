{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) tieredCache;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "immich";
  hostName = "midnight";
  subdomain = "photos";
  public = true;
  protected = false;
  serviceConfig = lib.mkMerge [
    {
      services = {
        immich = {
          enable = true;
          host = "0.0.0.0";
          mediaLocation = "${tieredCache.cachePool}/immich";
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

      # point immich-machine-learning to the updated runtime
      services.immich.machine-learning = {
        environment.LD_LIBRARY_PATH = "${pkgs.python312Packages.onnxruntime}/lib/python3.12/site-packages/onnxruntime/capi";
      };
    }
  ];
}
