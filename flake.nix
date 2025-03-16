{
  description = "My nix flake for system configuration, intended to be usable on NixOS and non-NixOS machines";

  inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      url = "nixpkgs/nixos-unstable";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations = {
        midnight = lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.default
            ./configuration.nix
          ];
          specialArgs = { inherit inputs; };
          system = "x86_64-linux";
        };
      };
    };
}
