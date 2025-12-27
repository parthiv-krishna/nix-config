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
    dig
    fastfetch
    fzf
    pciutils
    powertop
    ripgrep
    smartmontools
    trash-cli
    unzip
    usbutils
    wget
    zip
  ];
}
