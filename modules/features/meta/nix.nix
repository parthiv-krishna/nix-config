{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "nix"
  ];

  systemConfig =
    _cfg:
    { config, lib, ... }:
    let
      cacheUrl = lib.custom.mkPublicHttpsUrl config.constants "cache";
      cacheFqdn = lib.custom.mkPublicFqdn config.constants "cache";
      # nix-store --generate-binary-cache-key <cacheFqdn>-1 signing-key.private signing-key.public
      cachePublicKey = "${cacheFqdn}-1:x8wTeYCstMWT0jwzccBr3IT8V2DXqRKu8k/KUv5nW4Q=";
    in
    {
      nix.settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        substituters = [
          "https://cache.flox.dev?priority=30"
          "${cacheUrl}?priority=50"
        ];
        trusted-public-keys = [
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
          cachePublicKey
        ];

        # fallback if our cache goes offline
        fallback = true;
        connect-timeout = 5;
      };
    };
}
