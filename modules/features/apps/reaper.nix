# REAPER digital audio workstation feature - home-only
# Note: REAPER is unfree software
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "reaper" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.reaper ];

    unfree.allowedPackages = [ "reaper" ];

    custom.persistence.directories = [
      ".config/REAPER"
    ];
  };
}
