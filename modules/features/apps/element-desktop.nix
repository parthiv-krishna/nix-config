# Element Matrix client feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "element-desktop" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.element-desktop ];

    custom.persistence.directories = [
      ".config/Element"
    ];
  };
}
