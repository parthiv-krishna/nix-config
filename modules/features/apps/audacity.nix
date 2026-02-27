# Audacity audio editor feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "audacity" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.audacity ];

    custom.persistence.directories = [
      ".config/audacity"
    ];
  };
}
