{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "musescore"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.musescore ];

      custom.features.meta.impermanence.directories = [
        ".config/MuseScore"
      ];
    };
}
