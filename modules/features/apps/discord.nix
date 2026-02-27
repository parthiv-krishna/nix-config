# Discord chat client feature - home-only
# Note: Discord is unfree software
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "discord" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.discord ];

    custom.features.meta.unfree.allowedPackages = [ "discord" ];

    custom.features.meta.impermanence.directories = [
      ".config/discord"
    ];
  };
}
