# Intel GPU drivers feature - system-only
{ lib }:
lib.custom.mkFeature {
  path = [ "hardware" "gpu" "intel" ];

  systemConfig = cfg: { lib, pkgs, ... }: {
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
  };
}
