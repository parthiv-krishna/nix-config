{ config, lib, ... }:
{
  options.custom.manifests.sound-engineering.enable = lib.mkEnableOption "sound engineering features";

  config = lib.mkIf config.custom.manifests.sound-engineering.enable {
    custom.features = {
      apps.audacity.enable = lib.mkDefault true;
      apps.musescore.enable = lib.mkDefault true;
      apps.reaper.enable = lib.mkDefault true;
    };
  };
}
