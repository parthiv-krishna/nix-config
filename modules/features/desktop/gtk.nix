{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "gtk"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    {
      gtk = {
        enable = true;
        gtk4.theme = null;
        iconTheme = {
          name = "Papirus";
          package = pkgs.papirus-icon-theme;
        };
      };
    };
}
