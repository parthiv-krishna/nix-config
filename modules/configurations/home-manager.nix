{
  constants,
  inputs,
  mkCustomLib,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  mkHomeConfig =
    username:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${constants.systems.x86};
      modules = [
        ./home-manager-standalone.nix
      ];
      extraSpecialArgs = {
        inherit inputs username;
        lib = (mkCustomLib constants.systems.x86).extend (
          _final: _prev: {
            inherit (inputs.home-manager.lib) hm;
          }
        );
      };
    };
in
{
  flake.homeConfigurations = lib.genAttrs [
    "parthiv"
    "parthivk"
  ] mkHomeConfig;
}
