{
  description = "My nix flake for system configuration, intended to be usable on NixOS and non-NixOS machines";

  inputs = {
    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    copyparty = {
      url = "github:9001/copyparty";
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
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-config-secrets = {
      url = "git+ssh://git@github.com/parthiv-krishna/nix-config-secrets.git?ref=main&shallow=1";
      flake = false;
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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
      inherit (nixpkgs) lib;
      constants = import ./constants.nix;
      inherit (constants) hosts systems;
      forEachSystem = lib.genAttrs (lib.attrValues systems);

      # helper function to create custom lib for a system
      mkCustomLib =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        lib.extend (
          _: super:
          import ./lib {
            inherit inputs pkgs system;
            lib = super;
          }
        );
    in
    {
      # nixos system configurations
      nixosConfigurations = lib.mapAttrs (
        hostName: hostConfig:
        let
          inherit (hostConfig) system;
          customLib = mkCustomLib system;
        in
        lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            (customLib.custom.loadFeatures {
              path = ./modules/features;
              mode = "nixos";
              inherit customLib;
            })
            ./modules/manifests
            ./hosts/${hostName}
          ];
          specialArgs = {
            inherit inputs;
            lib = customLib;
          };
          inherit system;
        }
      ) hosts;

      # standalone home-manager configurations for non-NixOS systems
      # generate for each of the configured usernames
      homeConfigurations =
        let
          mkHomeConfig =
            username:
            let
              customLib = (mkCustomLib systems.x86).extend (
                _final: _prev: {
                  inherit (inputs.home-manager.lib) hm;
                }
              );
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${systems.x86};
              modules = [
                # Third-party modules needed by features
                inputs.nix-colors.homeManagerModules.default
                inputs.nixvim.homeModules.nixvim
                inputs.sops-nix.homeManagerModules.sops
                (customLib.custom.loadFeatures {
                  path = ./modules/features;
                  mode = "home";
                  inherit customLib;
                })
                ./modules/manifests
                ./hosts/standalone
              ];
              extraSpecialArgs = {
                inherit inputs username;
                lib = customLib;
              };
            };
          usernames = [
            "parthiv"
            "parthivk"
          ];
        in
        lib.genAttrs usernames mkHomeConfig;

      # `nix fmt`
      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        inputs.treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs = {
            black.enable = true;
            deadnix.enable = true;
            nixfmt.enable = true;
            statix.enable = true;
          };
        }
      );

      # Pre-commit
      checks = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./tools/checks.nix { inherit inputs pkgs system; }
      );

      # `nix develop`
      devShells = forEachSystem (
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
