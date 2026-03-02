{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "protonmail-desktop"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.protonmail-desktop ];

      custom.features.meta.impermanence.directories = [
        ".config/Proton Mail"
      ];
    };
}
