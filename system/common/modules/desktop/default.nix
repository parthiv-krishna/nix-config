{
  lib,
  ...
}:
{
  # only import the desktop environment if custom.desktop.enable is true
  options.custom.desktop = {
    enable = lib.mkEnableOption "custom.desktop";

    idleMinutes = {
      lock = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Number of idle minutes before the screen locks.";
        example = 15;
      };
      screenOff = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Number of idle minutes before the screen turns off.";
        example = 30;
      };
      suspend = lib.mkOption {
        type = lib.types.int;
        default = 15;
        description = "Number of idle minutes before the system suspends.";
        example = 60;
      };
    };
  };

  imports = lib.custom.scanPaths ./.;
}
