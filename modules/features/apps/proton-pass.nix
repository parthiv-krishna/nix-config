{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "proton-pass"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.proton-pass ];

      custom.features.meta.impermanence.directories = [
        ".config/Proton Pass"
      ];
    };
}
