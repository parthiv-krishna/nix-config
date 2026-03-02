# Required manifest - enables core features every host needs
{ config, lib, ... }:
{
  options.custom.manifests.required.enable = lib.mkEnableOption "required core features";

  config = lib.mkIf config.custom.manifests.required.enable {
    custom.features = {
      apps.git.enable = lib.mkDefault true;
      apps.bash.enable = lib.mkDefault true;
      meta.tailscale.enable = lib.mkDefault true;
    };
  };
}
