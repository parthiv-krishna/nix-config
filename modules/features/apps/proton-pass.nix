# Proton Pass password manager feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "proton-pass" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.proton-pass ];

    custom.features.meta.impermanence.directories = [
      ".config/Proton Pass"
    ];
  };
}
