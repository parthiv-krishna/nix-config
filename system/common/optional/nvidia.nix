{
  config,
  lib,
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
    "nvidia-x11"
    "nvidia-settings"
  ];

}
