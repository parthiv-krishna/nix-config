{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "curl"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.curl ];
    };
}
