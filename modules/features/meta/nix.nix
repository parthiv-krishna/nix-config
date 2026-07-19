{ lib }:
let
  nixSettings = config: {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://cache.flox.dev?priority=30"
      "${lib.custom.mkPublicHttpsUrl config.constants "cache"}?priority=50"
    ];
    trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "${lib.custom.mkPublicFqdn config.constants "cache"}-1:x8wTeYCstMWT0jwzccBr3IT8V2DXqRKu8k/KUv5nW4Q="
      "github-ci-1:0fNXOmbysSbsQNRgkqPDwxyDIFZwquLmnk/7gNrx/Us="
    ];

    # Fall back to building locally if a cache is unavailable.
    fallback = true;
    connect-timeout = 5;
  };
in
lib.custom.mkFeature {
  path = [
    "meta"
    "nix"
  ];

  systemConfig =
    _cfg:
    { config, ... }:
    {
      nix.settings = nixSettings config;
    };

  darwinConfig =
    _cfg:
    { config, ... }:
    {
      nix.settings = nixSettings config;
    };
}
