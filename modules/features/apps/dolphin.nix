# Dolphin file manager feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "dolphin" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.kdePackages.dolphin ];
  };
}
