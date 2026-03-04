{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "yazi"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.yazi ];
    };
}
