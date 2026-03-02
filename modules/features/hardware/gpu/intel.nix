{ lib }:
lib.custom.mkFeature {
  path = [
    "hardware"
    "gpu"
    "intel"
  ];

  systemConfig =
    _cfg:
    { lib, pkgs, ... }:
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

      custom.features.meta.unfree.allowedPackages = [
        "intel-ocl"
      ];

      environment.systemPackages = with pkgs; [
        intel-gpu-tools
        nvtopPackages.intel
      ];
    };
}
