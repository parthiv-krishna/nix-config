{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "dig"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.dig ];
    };
}
