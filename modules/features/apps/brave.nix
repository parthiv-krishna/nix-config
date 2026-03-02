{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "brave" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.brave ];

    custom.features.meta.impermanence.directories = [
      ".config/BraveSoftware"
    ];
  };
}
