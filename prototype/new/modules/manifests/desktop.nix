# Desktop environment manifest - enables hyprland and GUI apps
{ config, lib, ... }:
{
  options.custom.manifests.desktop.enable =
    lib.mkEnableOption "desktop environment";

  config = lib.mkIf config.custom.manifests.desktop.enable {
    custom.features = {
      desktop.hyprland.enable = lib.mkDefault true;
      apps.gui.enable = lib.mkDefault true;
      hardware.bluetooth.enable = lib.mkDefault true;
    };
  };
}
