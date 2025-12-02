{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.sound-engineering;

  packagesWithDirs = with pkgs; [
    {
      package = audacity;
      stateDir = ".config/audacity";
    }
    {
      package = musescore;
      stateDir = ".config/MuseScore";
    }
    {
      package = reaper;
      stateDir = ".config/REAPER";
    }
  ];

  packages = map (x: x.package) packagesWithDirs;

  persistenceDirs = map (x: x.stateDir) (
    builtins.filter (x: builtins.hasAttr "stateDir" x) packagesWithDirs
  );
in
{
  options.custom.sound-engineering = {
    enable = lib.mkEnableOption "Sound engineering package set";
  };

  config = lib.mkIf cfg.enable {
    home.packages = packages;

    unfree.allowedPackages = [
      "reaper"
    ];

    custom.persistence.directories = persistenceDirs;
  };
}
