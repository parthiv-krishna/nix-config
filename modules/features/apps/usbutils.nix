{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "usbutils"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.usbutils ];
    };
}
