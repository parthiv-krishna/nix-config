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

      boot.kernelParams = [
        # disable scatter/gather
        # "amdgpu.sg_display=0"

        # disable panel self refresh
        # https://gitlab.freedesktop.org/drm/amd/-/issues/3647
        "amdgpu.dcdebugmask=0x10"

        # disable micro engine scheduler
        # https://gitlab.freedesktop.org/drm/amd/-/issues/2065
        "amdgpu.mes=0"

        # disable mid-command buffer preemption
        # https://gitlab.freedesktop.org/drm/amd/-/issues/3131
        "amdgpu.mcbp=0"
      ];

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
