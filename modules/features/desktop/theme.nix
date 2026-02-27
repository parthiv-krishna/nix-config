# Theme configuration feature - home-only
# Provides font and colorscheme configuration via nix-colors
# Note: nix-colors homeManagerModule is imported via parthiv.nix sharedModules
{ lib, inputs }:
lib.custom.mkFeature {
  path = [ "desktop" "theme" ];

  extraOptions = {
    font = {
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Font package to use (defaults to monaspace if null)";
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

  homeConfig = cfg: { pkgs, ... }: {
    # nix-colors module is imported via parthiv.nix sharedModules
    colorScheme = inputs.nix-colors.colorSchemes.onedark;

    home.packages = [ (if cfg.font.package != null then cfg.font.package else pkgs.monaspace) ];
  };
}
