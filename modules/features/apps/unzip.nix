{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "unzip"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.unzip ];
    };
}
