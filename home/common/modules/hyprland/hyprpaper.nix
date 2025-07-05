{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.hyprland;
  nixColorsLib = inputs.nix-colors.lib.contrib { inherit pkgs; };
  wallpaper = nixColorsLib.nixWallpaperFromScheme {
    scheme = config.colorScheme;
    width = 1920;
    height = 1080;
    logoScale = 5.0;
  };
  wallpaperFile = "wallpaper.png";
in
lib.mkIf cfg.enable {
  home.file.${wallpaperFile}.source = wallpaper;

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "${config.home.homeDirectory}/${wallpaperFile}" ];
      wallpaper = [
        ",${config.home.homeDirectory}/${wallpaperFile}"
      ];
      ipc = false;
    };
  };
}
