{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "zulip"
  ];

  darwinConfig = _cfg: _: {
    homebrew.casks = [ "zulip" ];
  };

  homeConfig =
    _cfg:
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [ pkgs.zulip ];

      custom.features.meta.impermanence.directories = [
        ".config/Zulip"
      ];
    };
}
