{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "trash-cli"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.trash-cli ];
    };
}
