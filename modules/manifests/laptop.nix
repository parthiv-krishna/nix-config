{ config, lib, ... }:
{
  options.custom.manifests.laptop.enable = lib.mkEnableOption "laptop features";

  config = lib.mkIf config.custom.manifests.laptop.enable {
    custom.features = {
      apps = {
        pciutils.enable = lib.mkDefault true;
        powertop.enable = lib.mkDefault true;
        smartmontools.enable = lib.mkDefault true;
        usbutils.enable = lib.mkDefault true;
      };
    };
  };
}
