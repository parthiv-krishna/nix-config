{
  description = "My nix flake for system configuration, intended to be usable on NixOS and non-NixOS machines";

  inputs = {
    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "git+ssh://git@github.com/zhaofengli/colmena?ref=release-0.4.x";
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
      inherit (nixpkgs) lib; # equivalent to lib = nixpkgs.lib;
      systems = {
        x86 = "x86_64-linux";
        arm = "aarch64-linux";
      };
      forEachSystem = lib.genAttrs (lib.attrValues systems);
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
      # TODO: get from ./modules/constants.nix
      internalDomain = "ts.sub0.net";
    in
    {
      nixosConfigurations = lib.mapAttrs (
        hostName: hostConfig:
        let
          inherit (hostConfig) system;
          pkgs = nixpkgs.legacyPackages.${system};
          customLib = lib.extend (
            _: super:
            import ./lib {
              inherit inputs pkgs system;
              lib = super;
            }
          );
        in
        lib.nixosSystem {
          modules = [
            inputs.disko.nixosModules.default
            inputs.home-manager.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            inputs.crowdsec.nixosModules.crowdsec
            inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
            ./modules
            ./system/${hostName}
          ];
          specialArgs = {
            inherit inputs;
            lib = customLib;
          };
          inherit system;
        }
      ) hosts;

      # remote deployment
      colmena =
        {
          meta = {
            # build host
            nixpkgs = nixpkgs.legacyPackages.${systems.x86};
            nodeSpecialArgs = lib.mapAttrs (
              _hostName: hostConfig:
              let
                inherit (hostConfig) system;
                pkgs = nixpkgs.legacyPackages.${system};
                customLib = lib.extend (
                  _: super:
                  import ./lib {
                    inherit inputs pkgs system;
                    lib = super;
                  }
                );
              in
              {
                inherit inputs;
                lib = customLib;
              }
            ) hosts;
          };
        }
        // lib.mapAttrs (hostName: _hostConfig: {

          deployment = {
            targetHost = "${hostName}.${internalDomain}";
            # don't cross compile on ARM machines
            buildOnTarget = hostName != "vardar";
          };

          imports = [
            inputs.disko.nixosModules.default
            inputs.home-manager.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            inputs.crowdsec.nixosModules.crowdsec
            inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
            ./modules
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
