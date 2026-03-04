{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "btop"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.btop ];
    };
}
