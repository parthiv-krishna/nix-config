{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
  ];

  options.custom.font = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nerd-fonts.blex-mono;
      description = "Font package to use";
    };

    family = lib.mkOption {
      type = lib.types.str;
      default = "BlexMono Nerd Font";
      description = "Primary font family for UI elements";
    };

    monoFamily = lib.mkOption {
      type = lib.types.str;
      default = "BlexMono Nerd Font Mono";
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

  config = {
    colorScheme = inputs.nix-colors.colorSchemes.onedark;
  };
}
