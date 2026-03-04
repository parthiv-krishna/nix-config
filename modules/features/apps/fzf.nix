{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "fzf"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fzf ];
    };
}
