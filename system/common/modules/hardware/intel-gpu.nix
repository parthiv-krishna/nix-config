{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.intel-gpu;
in
{
  options.custom.intel-gpu = {
    enable = lib.mkEnableOption "Intel GPU drivers";
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
            intel-ocl
            intel-vaapi-driver
            libva-vdpau-driver
            libvdpau-va-gl
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
