{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "reaper"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.reaper ];

      custom.features.meta = {
        unfree.allowedPackages = [ "reaper" ];
        impermanence.directories = [ ".config/REAPER" ];
      };
    };
}
