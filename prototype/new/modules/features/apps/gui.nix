# GUI apps feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "gui" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [
      pkgs.firefox
      pkgs.element-desktop
    ];
  };
}
