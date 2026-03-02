# Hyprland feature - UNIFIED system + home config
# This is the key demonstration of mkFeature merging both configs
{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "hyprland"
  ];

  extraOptions = {
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

  # System-level config
  systemConfig =
    _cfg:
    { pkgs, ... }:
    {
      programs.hyprland.enable = true;

      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
            user = "testuser";
          };
        };
      };

      environment.systemPackages = [
        pkgs.kitty
        pkgs.waybar
      ];
    };

  # Home-level config - notice it can access cfg.idleMinutes from the SAME options!
  homeConfig =
    _cfg:
    _:
    {
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
