{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.desktop;
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;

    # xdg portal so apps can interact with eachother
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # login screen
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${config.programs.hyprland.package}/bin/start-hyprland";
          user = "parthiv";
        };
      };
    };

    fonts.packages = with pkgs; [
      font-awesome
    ];

    environment.systemPackages = with pkgs; [
      brightnessctl
      dunst
      kdePackages.dolphin
      kitty
      playerctl
      waybar
      wl-clipboard-rs
      wofi
    ];
  };
}
