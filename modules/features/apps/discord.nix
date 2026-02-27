# Discord chat client feature - home-only
# Note: Discord is unfree software
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "discord" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.discord ];

    unfree.allowedPackages = [ "discord" ];

    custom.persistence.directories = [
      ".config/discord"
    ];
  };
}
