{
  config,
  helpers,
  lib,
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
    "nvidia-x11"
    "nvidia-settings"
  ];

}
