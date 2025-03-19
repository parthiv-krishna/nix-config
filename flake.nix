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
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      inherit (nixpkgs) lib; # equivalent to lib = nixpkgs.lib;
      helpers = import ./helpers { inherit lib; };
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        midnight = lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.default
            inputs.home-manager.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            ./modules/unfree.nix
            ./system/midnight
          ];
          specialArgs = {
            inherit inputs;
            inherit helpers;
          };
          inherit system;
        };
      };

      # `nix fmt`
      formatter = {
        ${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
      };

      # Pre-commit checks
      checks = {
        ${system} =
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          import ./tools/checks.nix { inherit inputs system pkgs; };
      };

      # `nix develop`
      devShells = {
        ${system} = import ./tools/shell.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          checks = self.checks.${system};
        };
      };
    };
}
