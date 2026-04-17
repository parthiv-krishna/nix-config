{ lib }:
lib.custom.mkFeature {
  path = [ "desktop" ];

  extraOptions = {
    idleMinutes = {
      lock = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Number of idle minutes before the screen locks.";
      };
      screenOff = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Number of idle minutes before the screen turns off.";
      };
      suspend = lib.mkOption {
        type = lib.types.int;
        default = 15;
        description = "Number of idle minutes before the system suspends.";
      };
    };
  };

  # Sync NixOS values to home-manager config
  homeConfig = cfg: _: {
    custom.features.desktop.idleMinutes = cfg.idleMinutes;
  };
}
