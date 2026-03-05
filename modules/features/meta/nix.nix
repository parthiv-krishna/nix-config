{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "nix"
  ];

  systemConfig = _cfg: _: {
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
