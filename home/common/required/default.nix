{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  # core utils
  home.packages = with pkgs; [
    btop
    curl
    fastfetch
    fzf
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
