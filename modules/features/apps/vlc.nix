{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "vlc"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [
        (if pkgs.stdenv.hostPlatform.isDarwin then pkgs.vlc-bin else pkgs.vlc)
      ];

      custom.features.meta.impermanence.directories = [
        ".config/vlc"
      ];
    };
}
