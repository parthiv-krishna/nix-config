# GUI apps module - home side
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.gui-apps;
in
{
  options.custom.gui-apps = {
    enable = lib.mkEnableOption "GUI applications";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      firefox
      # Using a free app instead of discord for the prototype
      element-desktop
    ];
  };
}
