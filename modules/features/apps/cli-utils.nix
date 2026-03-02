{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "cli-utils"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
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
        yazi
        zip
      ];
    };
}
