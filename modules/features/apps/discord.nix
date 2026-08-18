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
        unfree.allowedPackages = [
          "discord"
          "discord-unwrapped"
        ];
        impermanence.directories = [ ".config/discord" ];
      };
    };
}
