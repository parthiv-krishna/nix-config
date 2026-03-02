{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "unfree"
  ];

  extraOptions = {
    allowedPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "nvidia-x11"
        "steam"
        "discord"
      ];
      description = "List of unfree packages to allow";
    };
  };

  systemConfig = cfg: _: {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.allowedPackages;
  };

  homeConfig =
    cfg:
    { config, lib, ... }:
    let
      # Merge packages from osConfig (via cfg) and home-manager config
      hmPackages = config.custom.features.meta.unfree.allowedPackages or [ ];
      allPackages = cfg.allowedPackages ++ hmPackages;
    in
    {
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allPackages;
    };
}
