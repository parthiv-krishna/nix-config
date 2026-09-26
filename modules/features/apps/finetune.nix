{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "finetune"
  ];

  darwinConfig = _cfg: _: {
    homebrew.casks = [ "finetune" ];
  };
}
