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
    fzf
    htop
    pciutils
    powertop
    ripgrep
    trash-cli
    unzip
    usbutils
    wget
    zip
  ];
}
