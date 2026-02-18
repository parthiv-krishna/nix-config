# allows multiple declaration of unfree.allowedPackages to merge automatically
# and build the correct allowUnfreePredicate for Home Manager

{
  config,
  lib,
  ...
}:
{
  options = {
    unfree = with lib; {
      allowedPackages = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "discord"
          "steam"
        ];
        description = "List of unfree packages to allow in Home Manager";
      };
    };
  };
  config = {
    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) config.unfree.allowedPackages;
  };
}
