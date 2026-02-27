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

  systemConfig = cfg: { ... }: {
    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) cfg.allowedPackages;
  };

  homeConfig = cfg: { ... }: {
    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) cfg.allowedPackages;
  };
}
