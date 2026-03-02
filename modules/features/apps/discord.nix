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

      custom.features.meta.unfree.allowedPackages = [ "discord" ];

      custom.features.meta.impermanence.directories = [
        ".config/discord"
      ];
    };
}
