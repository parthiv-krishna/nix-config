{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "pciutils"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.pciutils ];
    };
}
