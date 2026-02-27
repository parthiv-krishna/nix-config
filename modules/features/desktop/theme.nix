# Theme configuration feature - home-only
# Provides font and colorscheme configuration via nix-colors
{ lib, pkgs, inputs }:
lib.custom.mkFeature {
  path = [ "desktop" "theme" ];

  extraOptions = {
    font = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.monaspace;
        description = "Font package to use";
      };

      family = lib.mkOption {
        type = lib.types.str;
        default = "Monaspace Neon";
        description = "Primary font family for UI elements";
      };

      monoFamily = lib.mkOption {
        type = lib.types.str;
        default = "Monaspace Neon";
        description = "Monospace font family for terminals and code";
      };

      sizes = {
        desktop = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Font size for desktop elements";
        };

        applications = lib.mkOption {
          type = lib.types.int;
          default = 12;
          description = "Font size for applications";
        };

        terminal = lib.mkOption {
          type = lib.types.int;
          default = 12;
          description = "Font size for terminal";
        };
      };
    };
  };

  homeConfig = cfg: { inputs, ... }: {
    imports = [
      inputs.nix-colors.homeManagerModules.default
    ];

    colorScheme = inputs.nix-colors.colorSchemes.onedark;

    home.packages = [ cfg.font.package ];
  };
}
