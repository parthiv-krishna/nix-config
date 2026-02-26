{
  description = "Prototype - current structure mock";

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

      # Custom lib with scanPaths
      customLib = lib.extend (
        _: _: {
          custom = {
            scanPaths =
              dirPath:
              let
                fileAttrs = builtins.readDir dirPath;
                nixFileNames = builtins.attrNames (
                  lib.attrsets.filterAttrs (
                    name: type:
                    type == "directory" || (lib.strings.hasSuffix ".nix" name && name != "default.nix")
                  ) fileAttrs
                );
              in
              builtins.map (name: dirPath + "/${name}") nixFileNames;
          };
        }
      );
    in
    {
      # NixOS configuration for testhost
      nixosConfigurations.testhost = customLib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          ./system/common/modules
          ./system/testhost
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
          ./home/common/modules
          ./home/standalone.nix
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
