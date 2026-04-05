{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "niri"
    "swaybg"
  ];

  homeConfig =
    _cfg:
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    let
      nixColorsLib = inputs.nix-colors.lib.contrib { inherit pkgs; };
      wallpaper = nixColorsLib.nixWallpaperFromScheme {
        scheme = config.colorScheme;
        width = 1920;
        height = 1080;
        logoScale = 5.0;
      };
    in
    {
      # swaybg service for wallpaper
      systemd.user.services.swaybg = {
        Unit = {
          Description = "Wayland wallpaper daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
