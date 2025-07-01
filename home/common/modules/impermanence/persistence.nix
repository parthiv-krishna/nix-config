{
  lib,
  ...
}:
{
  # wrapper around persistence options
  # passed through to home.persistence."/persist/home/parthiv" on NixOS hosts
  # no-op on standalone home-manager systems
  options.custom.persistence = {
    directories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of directories to persist.";
    };

    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of files to persist.";
    };
  };
}
