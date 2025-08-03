{
  description = "My nix flake for system configuration, intended to be usable on NixOS and non-NixOS machines";

  inputs = {
    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena?ref=release-0.4.x";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crowdsec = {
      url = "git+https://codeberg.org/kampka/nix-flake-crowdsec.git";
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
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
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
    thaw = {
      url = "github:parthiv-krishna/thaw";
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
      inherit (nixpkgs) lib; # equivalent to lib = nixpkgs.lib;
      systems = {
        x86 = "x86_64-linux";
        arm = "aarch64-linux";
      };
      forEachSystem = lib.genAttrs (lib.attrValues systems);
      # Build NixOS configurations for each host
      hosts = {
        icicle = {
          system = systems.x86;
          buildOnTarget = true;
          allowLocalDeployment = true;
        };
        midnight = {
          system = systems.x86;
          buildOnTarget = true;
          allowLocalDeployment = false;
        };
        nimbus = {
          system = systems.arm;
          buildOnTarget = true;
          allowLocalDeployment = false;
        };
        vardar = {
          system = systems.x86;
          buildOnTarget = false;
          allowLocalDeployment = false;
        };
      };
      # TODO: get from ./system/common/modules/constants.nix
      internalDomain = "ts.sub0.net";

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
      nixosConfigurations = lib.mapAttrs (
        hostName: hostConfig:
        let
          inherit (hostConfig) system;
          customLib = mkCustomLib system;
        in
        lib.nixosSystem {
          modules = [
            ./system/common/modules
            ./system/${hostName}
          ];
          specialArgs = {
            inherit inputs;
            lib = customLib;
          };
          inherit system;
        }
      ) hosts;

      # standalone home-manager configurations for non-NixOS systems
      homeConfigurations = {
        # default standalone configuration using x86_64-linux
        parthiv = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${systems.x86};
          modules = [
            ./home/common/modules
            ./home/standalone.nix
          ];
          extraSpecialArgs = {
            inherit inputs;
            lib = (mkCustomLib systems.x86).extend (
              _final: _prev: {
                inherit (inputs.home-manager.lib) hm;
              }
            );
          };
        };
      };

      # remote deployment
      colmena = {
        meta = {
          # build host
          nixpkgs = nixpkgs.legacyPackages.${systems.x86};
          nodeSpecialArgs = lib.mapAttrs (
            _hostName: hostConfig:
            let
              inherit (hostConfig) system;
            in
            {
              inherit inputs;
              lib = mkCustomLib system;
            }
          ) hosts;
        };
      }
      // lib.mapAttrs (hostName: hostConfig: {

        deployment = {
          targetHost = "${hostName}.${internalDomain}";
          inherit (hostConfig) buildOnTarget allowLocalDeployment;
        };

        imports = [
          ./system/common/modules
          ./system/${hostName}
        ];

      }) hosts;

      # `nix fmt`
      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        inputs.treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs = {
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
