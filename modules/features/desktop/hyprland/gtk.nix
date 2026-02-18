{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hyprland;
in
lib.mkIf cfg.enable {
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };

}
