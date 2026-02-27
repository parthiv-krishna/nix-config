# ProtonVPN GUI client feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "protonvpn-gui" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.protonvpn-gui ];

    custom.features.meta.impermanence.directories = [
      ".config/Proton"
    ];
  };
}
