# MuseScore music notation software feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "musescore" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.musescore ];

    custom.persistence.directories = [
      ".config/MuseScore"
    ];
  };
}
