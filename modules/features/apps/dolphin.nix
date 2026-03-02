{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "dolphin"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.kdePackages.dolphin ];
    };
}
