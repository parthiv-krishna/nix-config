# Proton Mail desktop client feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "protonmail-desktop" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.protonmail-desktop ];

    custom.features.meta.impermanence.directories = [
      ".config/Proton Mail"
    ];
  };
}
