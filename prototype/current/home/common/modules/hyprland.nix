# Hyprland module - home side
# This is the home counterpart to system/common/modules/desktop.nix
{ config, lib, ... }:
let
  cfg = config.custom.hyprland;
in
{
  options.custom.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager (home config)";
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = ",preferred,auto,1";

        "$mainMod" = "SUPER";

        bind = [
          "$mainMod, Return, exec, kitty"
          "$mainMod, Q, killactive,"
          "$mainMod, Space, exec, wofi --show drun"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
        };
      };
    };

    # Home services for desktop
    services.dunst.enable = true;

    programs.kitty = {
      enable = true;
      settings = {
        font_size = 12;
      };
    };

    programs.waybar.enable = true;
  };
}
