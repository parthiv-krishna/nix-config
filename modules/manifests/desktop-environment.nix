{ config, lib, ... }:
{
  options.custom.manifests.desktop-environment.enable =
    lib.mkEnableOption "desktop environment features";

  config = lib.mkIf config.custom.manifests.desktop-environment.enable {
    custom.features = {
      # Desktop
      desktop.hyprland.enable = lib.mkDefault true;
      desktop.theme.enable = lib.mkDefault true;

      # Desktop apps
      apps.kitty.enable = lib.mkDefault true;
      apps.brave.enable = lib.mkDefault true;
      apps.discord.enable = lib.mkDefault true;
      apps.dolphin.enable = lib.mkDefault true;
      apps.element-desktop.enable = lib.mkDefault true;
      apps.librewolf.enable = lib.mkDefault true;
      apps.protonmail-desktop.enable = lib.mkDefault true;
      apps.protonvpn-gui.enable = lib.mkDefault true;
      apps.proton-pass.enable = lib.mkDefault true;
      apps.signal-desktop.enable = lib.mkDefault true;

      # Hardware
      hardware.bluetooth.enable = lib.mkDefault true;
      hardware.audio.enable = lib.mkDefault true;
    };
  };
}
