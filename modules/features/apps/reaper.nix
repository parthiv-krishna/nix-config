# REAPER digital audio workstation feature - home-only
# Note: REAPER is unfree software
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "reaper" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.reaper ];

    custom.features.meta.unfree.allowedPackages = [ "reaper" ];

    custom.features.meta.impermanence.directories = [
      ".config/REAPER"
    ];
  };
}
