{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "audacity" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.audacity ];

    custom.features.meta.impermanence.directories = [
      ".config/audacity"
    ];
  };
}
