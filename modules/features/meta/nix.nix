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
      cacheFqdn = lib.custom.mkPublicFqdn config.constants "cache";
      cacheUrl = lib.custom.mkPublicHttpsUrl config.constants "cache";
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
          cacheUrl
          "https://cache.nixos.org"
          "https://cache.nixos-cuda.org"
        ];
        trusted-public-keys = [
          cachePublicKey
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];

        # fallback if our cache goes offline
        fallback = true;
        connect-timeout = 5;
      };
    };
}
