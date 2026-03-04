{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "wget"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.wget ];
    };
}
