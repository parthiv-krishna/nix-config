{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "homebrew"
  ];

  darwinConfig = _cfg: _: {
    homebrew = {
      enable = true;
      onActivation.cleanup = "uninstall";
    };
  };
}
