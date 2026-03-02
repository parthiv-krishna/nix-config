{ lib }:
lib.custom.mkFeature {
  path = [ "desktop" "hyprland" "gtk" ];

  homeConfig = cfg: { pkgs, ... }: {
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
      };
    };
  };
}
