# Brave web browser feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "brave" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.brave ];

    custom.persistence.directories = [
      ".config/BraveSoftware"
    ];
  };
}
