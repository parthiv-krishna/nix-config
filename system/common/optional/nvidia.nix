{
  config,
  lib,
  pkgs,
  ...
}:

{

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;

    open = lib.mkDefault true;

    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
  };

  unfree.allowedPackages = [
    "cuda_cccl"
    "cuda_cudart"
    "cuda_cuobjdump"
    "cuda_cupti"
    "cuda_cuxxfilt"
    "cuda_gdb"
    "cuda_nvcc"
    "cuda_nvdisasm"
    "cuda_nvml_dev"
    "cuda_nvrtc"
    "cuda_nvtx"
    "cuda-merged"
    "cuda_nvprune"
    "cuda_profiler_api"
    "cuda_sanitizer_api"
    "libcublas"
    "libcufft"
    "libcurand"
    "libcusolver"
    "libcusparse"
    "libnpp"
    "libnvjitlink"
    "nvidia-x11"
    "nvidia-settings"
  ];

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

}
