{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  # core utils
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
