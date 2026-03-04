{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "ripgrep"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ripgrep ];
    };
}
