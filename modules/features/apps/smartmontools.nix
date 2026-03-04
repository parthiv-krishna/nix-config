{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "smartmontools"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.smartmontools ];
    };
}
