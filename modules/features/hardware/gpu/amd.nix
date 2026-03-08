{ lib }:
lib.custom.mkFeature {
  path = [
    "hardware"
    "gpu"
    "amd"
  ];

  systemConfig =
    _cfg:
    { pkgs, ... }:
    {
      services.xserver.videoDrivers = [ "modesetting" ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = with pkgs; [
          libvdpau-va-gl
          libva-vdpau-driver
        ];
      };

      hardware.amdgpu.initrd.enable = true;

      environment.sessionVariables = {
        # explicitly tell apps to use the AMD VA-API driver
        LIBVA_DRIVER_NAME = "radeonsi";
        # ensure Wayland apps use the correct GPU
        WLR_DRM_NO_ATOMIC = "1";
      };

      environment.systemPackages = with pkgs; [
        nvtopPackages.amd
        libva-utils
        vulkan-tools
      ];
    };
}
