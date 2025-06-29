{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  environment.systemPackages = with pkgs; [
    # includes smartctl
    smartmontools
  ];
}
