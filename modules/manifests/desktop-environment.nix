{ config, lib, ... }:
{
  options.custom.manifests.desktop-environment.enable =
    lib.mkEnableOption "desktop environment features";

  config = lib.mkIf config.custom.manifests.desktop-environment.enable {
    custom.features = {
      desktop = {
        hyprland = {
          enable = lib.mkDefault true;
          dunst.enable = lib.mkDefault true;
          gtk.enable = lib.mkDefault true;
          hypridle.enable = lib.mkDefault true;
          hyprpaper.enable = lib.mkDefault true;
          waybar.enable = lib.mkDefault true;
          wofi.enable = lib.mkDefault true;
        };
        theme.enable = lib.mkDefault true;
      };

      apps = {
        kitty.enable = lib.mkDefault true;
        brave.enable = lib.mkDefault true;
        discord.enable = lib.mkDefault true;
        dolphin.enable = lib.mkDefault true;
        element-desktop.enable = lib.mkDefault true;
        librewolf.enable = lib.mkDefault true;
        protonmail-desktop.enable = lib.mkDefault true;
        protonvpn-gui.enable = lib.mkDefault true;
        proton-pass.enable = lib.mkDefault true;
        signal-desktop.enable = lib.mkDefault true;
      };

      hardware = {
        bluetooth.enable = lib.mkDefault true;
        audio.enable = lib.mkDefault true;
      };
    };
  };
}
