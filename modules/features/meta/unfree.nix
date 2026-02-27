# Unfree package allowlist feature - MERGE (system and home)
{ lib }:
lib.custom.mkFeature {
  path = [ "meta" "unfree" ];

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

  systemConfig = cfg: { config, lib, ... }: {
    # Define the unfree.allowedPackages option for system
    options.unfree.allowedPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of unfree packages to allow";
    };

    config = {
      unfree.allowedPackages = cfg.allowedPackages;
      nixpkgs.config.allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) config.unfree.allowedPackages;
    };
  };

  homeConfig = cfg: { config, lib, ... }: {
    # Define the unfree.allowedPackages option for home-manager
    options.unfree.allowedPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of unfree packages to allow in Home Manager";
    };

    config = {
      unfree.allowedPackages = cfg.allowedPackages;
      nixpkgs.config.allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) config.unfree.allowedPackages;
    };
  };
}
