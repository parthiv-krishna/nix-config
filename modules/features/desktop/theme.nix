{ lib, inputs }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "theme"
  ];

  extraOptions = {
    font = {
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Font package to use (defaults to nerd-fonts.zed-mono if null)";
      };

      family = lib.mkOption {
        type = lib.types.str;
        default = "ZedMono Nerd Font";
        description = "Primary font family for UI elements";
      };

      monoFamily = lib.mkOption {
        type = lib.types.str;
        default = "ZedMono Nerd Font Mono";
        description = "Monospace font family for terminals and code";
      };

      sizes = {
        small = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "Small font size";
        };

        normal = lib.mkOption {
          type = lib.types.int;
          default = 12;
          description = "Normal font size";
        };

        large = lib.mkOption {
          type = lib.types.int;
          default = 14;
          description = "Large font size";
        };

        xlarge = lib.mkOption {
          type = lib.types.int;
          default = 16;
          description = "Extra large font size";
        };
      };
    };
  };

  homeConfig =
    cfg:
    { pkgs, ... }:
    {
      colorScheme = inputs.nix-colors.colorSchemes.onedark;

      home.packages = [
        (if cfg.font.package != null then cfg.font.package else pkgs.nerd-fonts.zed-mono)
      ];
    };
}
