# allows multiple declaration of unfree.allowedPackages to merge automatically
# and build the correct allowUnfreePredicate

{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
{
  options = {
    unfree = with lib; {
      allowedPackages = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "nvidia-x11"
          "steam"
        ];
        description = "List of unfree packages to allow";
      };
    };
  };
  config = {
    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) config.unfree.allowedPackages;
  };
}
