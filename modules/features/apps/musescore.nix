# MuseScore music notation software feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "musescore" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.musescore ];

    custom.features.meta.impermanence.directories = [
      ".config/MuseScore"
    ];
  };
}
