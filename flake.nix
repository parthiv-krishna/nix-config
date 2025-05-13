{
  description = "My nix flake for system configuration, intended to be usable on NixOS and non-NixOS machines";

  inputs = {
    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nix-config-secrets = {
      url = "git+ssh://git@github.com/parthiv-krishna/nix-config-secrets.git?ref=main&shallow=1";
      flake = false;
    };
    nixpkgs = {
      url = "nixpkgs/nixos-unstable";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
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
      systems = {
        x86 = "x86_64-linux";
        arm = "aarch64-linux";
      };
      # Build NixOS configurations for each host
      hosts = {
        midnight = {
          system = systems.x86;
        };
        vardar = {
          system = systems.x86;
        };
        nimbus = {
          system = systems.arm;
        };
      };
    in
    {
      nixosConfigurations = lib.mapAttrs (
        hostname: hostConfig:
        let
          # Per-host system, pkgs, and helpers
          inherit (hostConfig) system;
          pkgs = nixpkgs.legacyPackages.${system};
          helpers = import ./helpers {
            inherit
              inputs
              lib
              pkgs
              system
              ;
          };
        in
        lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.default
            inputs.home-manager.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            ./modules/unfree.nix
            ./system/${hostname}
          ];
          specialArgs = {
            inherit helpers inputs;
          };
          inherit system;
        }
      ) hosts;

      # `nix fmt`
      formatter = lib.genAttrs (lib.attrValues systems) (
        system: nixpkgs.legacyPackages.${system}.nixfmt-tree
      );

      # Pre-commit
      checks = lib.genAttrs (lib.attrValues systems) (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./tools/checks.nix { inherit inputs pkgs system; }
      );

      # `nix develop`
      devShells = lib.genAttrs (lib.attrValues systems) (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./tools/shell.nix {
          inherit pkgs;
          checks = self.checks.${system};
        }
      );
    };
}
