{
  config,
  pkgs,
  ...
}:

{

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    open = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
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

  nixpkgs.config = {
    cudaSupport = true;
    cudaCapability = "8.6"; # 3060
  };

  hardware.nvidia-container-toolkit.enable = true;

  # fixes GPU disappearing after suspend/resume
  systemd.services."nvidia-uvm-reload" = {
    description = "Reload nvidia_uvm after resume";
    wantedBy = [ "sleep.target" ];
    after = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        modprobe -r nvidia_uvm
        modprobe nvidia_uvm
      '';
    };
  };

}
