{
  lib,
  ...
}:
{
  options.custom.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop environment";
  };

  imports = lib.custom.scanPaths ./.;
}
