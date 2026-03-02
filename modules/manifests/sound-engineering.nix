{ config, lib, ... }:
{
  options.custom.manifests.sound-engineering.enable = lib.mkEnableOption "sound engineering features";

  config = lib.mkIf config.custom.manifests.sound-engineering.enable {
    custom.features.apps = {
      audacity.enable = lib.mkDefault true;
      musescore.enable = lib.mkDefault true;
      reaper.enable = lib.mkDefault true;
    };
  };
}
