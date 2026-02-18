{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  constants = import ../constants.nix;
  inherit (constants) systems;

  mkCustomLib =
    system:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    lib.extend (
      _: super:
      import ../lib {
        inherit inputs pkgs system;
        lib = super;
      }
    );
in
{
  systems = lib.attrValues systems;

  _module.args = {
    inherit constants mkCustomLib;
  };

  perSystem =
    { system, config, ... }:
    let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      formatter = inputs.treefmt-nix.lib.mkWrapper pkgs {
        projectRootFile = "flake.nix";
        programs = {
          black.enable = true;
          deadnix.enable = true;
          nixfmt.enable = true;
          statix.enable = true;
        };
      };

      checks = import ../tools/checks.nix {
        inherit inputs pkgs system;
      };

      devShells.default = import ../tools/shell.nix {
        inherit pkgs;
        inherit (config) checks;
      };
    };
}
