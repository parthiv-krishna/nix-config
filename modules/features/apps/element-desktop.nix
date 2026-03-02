{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "element-desktop" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.element-desktop ];

    custom.features.meta.impermanence.directories = [
      ".config/Element"
    ];
  };
}
