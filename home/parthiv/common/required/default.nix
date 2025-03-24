{
  helpers,
  pkgs,
  ...
}:
{
  imports = helpers.scanPaths ./.;

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
