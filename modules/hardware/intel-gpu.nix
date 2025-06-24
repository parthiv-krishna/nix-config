{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hardware.intel-gpu;
in
{
  options.custom.hardware.intel-gpu = {
    enable = lib.mkEnableOption "custom.intel-gpu";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.xserver.videoDrivers = [ "intel" ];

        hardware.graphics = {
          enable = lib.mkDefault true;

          extraPackages = with pkgs; [
            intel-compute-runtime
            intel-media-driver
            vaapiVdpau
            libvdpau-va-gl
            vaapiIntel
            intel-ocl
            vpl-gpu-rt
          ];
        };

        unfree.allowedPackages = [
          "intel-ocl"
        ];

        environment.systemPackages = with pkgs; [
          intel-gpu-tools
          nvtopPackages.intel
        ];
      }
    ]
  );
}
