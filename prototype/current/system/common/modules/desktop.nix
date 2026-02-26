# Desktop/Hyprland module - system side
# This demonstrates the split between system and home config
{ config, lib, pkgs, ... }:
let
  cfg = config.custom.desktop;
in
{
  options.custom.desktop = {
    enable = lib.mkEnableOption "Desktop environment";
    
    idleMinutes = {
      lock = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Minutes before screen locks";
      };
      screenOff = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Minutes before screen turns off";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # System-level hyprland config
    programs.hyprland.enable = true;

    # Login screen
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "testuser";
        };
      };
    };

    # System packages for desktop
    environment.systemPackages = with pkgs; [
      kitty
      waybar
    ];
  };
}
