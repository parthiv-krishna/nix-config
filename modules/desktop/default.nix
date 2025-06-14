{
  lib,
  ...
}:
{
  # only import the desktop environment if custom.desktop.enable is true
  options.custom.desktop.enable = lib.mkEnableOption "custom.desktop";

  imports = lib.custom.scanPaths ./.;
}
