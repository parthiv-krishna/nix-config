{ config, lib, ... }:
{
  options.custom.manifests.server.enable = lib.mkEnableOption "server features";

  config = lib.mkIf config.custom.manifests.server.enable {
    custom.features = {
      networking.sshd.enable = lib.mkDefault true;
    };
  };
}
