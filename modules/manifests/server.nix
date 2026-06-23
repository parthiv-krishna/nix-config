{ config, lib, ... }:
{
  options.custom.manifests.server.enable = lib.mkEnableOption "server features";

  config = lib.mkIf config.custom.manifests.server.enable {
    custom.features = {
      apps = {
        pciutils.enable = lib.mkDefault true;
        smartmontools.enable = lib.mkDefault true;
        usbutils.enable = lib.mkDefault true;
      };
      networking = {
        sshd.enable = lib.mkDefault true;
        tailscale.isServer = lib.mkDefault true;
      };
    };
  };
}
