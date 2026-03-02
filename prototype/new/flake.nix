{
  description = "Prototype - new structure with mkFeature";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      # Build custom lib with all helpers
      customLib = lib.extend (_: _: import ./lib { inherit lib; });

      # Helper to load features with mode
      loadFeatures =
        mode:
        customLib.custom.loadFeatures {
          path = ./modules/features;
          inherit mode customLib;
        };
    in
    {
      # NixOS configuration for testhost
      nixosConfigurations.testhost = customLib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          (loadFeatures "nixos")
          ./modules/manifests
          ./hosts/testhost
        ];
        specialArgs = {
          inherit inputs;
          lib = customLib;
        };
      };

      # Standalone home-manager configuration
      homeConfigurations.testuser = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          (loadFeatures "home")
          ./hosts/standalone
        ];
        extraSpecialArgs = {
          inherit inputs;
          lib = customLib.extend (
            _final: _prev: {
              inherit (home-manager.lib) hm;
            }
          );
        };
      };
    };
}
