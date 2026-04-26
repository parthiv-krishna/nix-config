{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "proton-vpn"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.proton-vpn ];

      custom.features.meta.impermanence.directories = [
        ".config/Proton"
      ];
    };
}
