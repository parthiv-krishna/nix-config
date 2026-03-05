{ lib, inputs }:
lib.custom.mkFeature {
  path = [
    "meta"
    "theme"
  ];

  extraOptions = pkgs: {
    font = {
      enable = lib.mkEnableOption "font configuration";

      package = lib.mkPackageOption pkgs "font" {
        default = [
          "nerd-fonts"
          "zed-mono"
        ];
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

  homeConfig = cfg: _: {
    colorScheme = inputs.nix-colors.colorSchemes.onedark;

    home.packages = lib.mkIf cfg.font.enable [ cfg.font.package ];
  };
}
