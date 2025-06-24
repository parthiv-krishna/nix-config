{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hardware.nvidia;
in
{
  options.custom.hardware.nvidia = {
    enable = lib.mkEnableOption "custom.nvidia";
    cudaCapability = lib.mkOption {
      type = lib.types.str;
      description = "CUDA capability level for the installed GPU";
      example = "8.6";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
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
          inherit (cfg) cudaCapability;
        };

        hardware.nvidia-container-toolkit.enable = true;

        # fixes GPU disappearing after suspend/resume
        systemd.services."nvidia-reload" = {
          description = "Reload nvidia_uvm driver after resume";
          wantedBy = [ "sleep.target" ];
          after = [ "sleep.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScriptBin "nvidia-reload.sh" ''
              ${pkgs.kmod}/bin/modprobe -rv nvidia_uvm
              sleep 1
              ${pkgs.kmod}/bin/modprobe -v nvidia_uvm
            ''}/bin/nvidia-reload.sh";
          };
        };
      }
    ]
  );
}
