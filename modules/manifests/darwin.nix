{ config, lib, ... }:
{
  options.custom.manifests.darwin.enable =
    lib.mkEnableOption "Darwin desktop with common apps and features";

  config = lib.mkIf config.custom.manifests.darwin.enable {
    custom = {
      manifests.desktop-core.enable = lib.mkDefault true;

      features = {
        apps.vlc.enable = lib.mkDefault true;

        desktop.darwin = {
          enable = lib.mkDefault true;
          scroll-reverser.enable = lib.mkDefault true;
        };
      };
    };
  };
}
