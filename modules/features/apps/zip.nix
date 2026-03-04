{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "zip"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zip ];
    };
}
