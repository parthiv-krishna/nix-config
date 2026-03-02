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

      custom.features.meta.unfree.allowedPackages = [ "reaper" ];

      custom.features.meta.impermanence.directories = [
        ".config/REAPER"
      ];
    };
}
