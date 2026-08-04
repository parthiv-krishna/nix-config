{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "comma"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.comma ];
    };
}
