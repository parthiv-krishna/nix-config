{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "fastfetch"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fastfetch ];
    };
}
