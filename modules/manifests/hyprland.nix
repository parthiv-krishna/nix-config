{ config, lib, ... }:
{
  options.custom.manifests.hyprland.enable =
    lib.mkEnableOption "hyprland compositor with common desktop components";

  config = lib.mkIf config.custom.manifests.hyprland.enable {
    custom = {
      manifests.desktop-core.enable = lib.mkDefault true;

      features.desktop = {
        enable = lib.mkDefault true;
        hyprland = {
          enable = lib.mkDefault true;
          hypridle.enable = lib.mkDefault true;
          hyprpaper.enable = lib.mkDefault true;
        };
        dunst.enable = lib.mkDefault true;
        gtk.enable = lib.mkDefault true;
        waybar = {
          enable = lib.mkDefault true;
          compositor = "hyprland";
        };
        wofi.enable = lib.mkDefault true;
      };
    };
  };
}
