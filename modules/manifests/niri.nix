{ config, lib, ... }:
{
  options.custom.manifests.niri.enable =
    lib.mkEnableOption "niri compositor with common desktop components";

  config = lib.mkIf config.custom.manifests.niri.enable {
    custom = {
      manifests.desktop-core.enable = lib.mkDefault true;

      features.desktop = {
        niri = {
          enable = lib.mkDefault true;
          swayidle.enable = lib.mkDefault true;
          swaybg.enable = lib.mkDefault true;
        };
        dunst.enable = lib.mkDefault true;
        gtk.enable = lib.mkDefault true;
        waybar = {
          enable = lib.mkDefault true;
          compositor = "niri";
        };
        wofi.enable = lib.mkDefault true;
      };
    };
  };
}
