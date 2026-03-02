{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "protonvpn-gui"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      home.packages = [ pkgs.protonvpn-gui ];

      custom.features.meta.impermanence.directories = [
        ".config/Proton"
      ];
    };
}
