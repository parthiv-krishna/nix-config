{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "discord"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.discord ];

      custom.features.meta = {
        unfree.allowedPackages = [ "discord" ];
        impermanence.directories = [ ".config/discord" ];
      };
    };
}
