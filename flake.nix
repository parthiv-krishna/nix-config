{
  description = "My nix flake for system configuration, intended to be usable on NixOS and non-NixOS machines";

  inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    nixpkgs = {
      url = "nixpkgs/nixos-unstable";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib;
      helpers = import ./helpers { inherit lib; };
    in
    {
      nixosConfigurations = {
        midnight = lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.default
            inputs.home-manager.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            ./system/midnight
          ];
          specialArgs = {
            inherit inputs;
            inherit helpers;
          };
          system = "x86_64-linux";
        };
      };
    };
}
