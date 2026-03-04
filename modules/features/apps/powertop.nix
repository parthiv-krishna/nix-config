{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "powertop"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.powertop ];
    };
}
