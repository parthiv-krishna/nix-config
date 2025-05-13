{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.packages = with pkgs; [
    curl
    fastfetch
    htop
    pciutils
    powertop
    trash-cli
    unzip
    usbutils
    wget
    zip
  ];
}
