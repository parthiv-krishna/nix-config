{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "vlc"
  ];

  darwinConfig = _cfg: _: {
    homebrew.casks = [ "vlc" ];
  };

  homeConfig =
    _cfg:
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [ pkgs.vlc ];

      custom.features.meta.impermanence.directories = [
        ".config/vlc"
      ];
    };
}
