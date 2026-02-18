{
  constants,
  inputs,
  mkCustomLib,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
in
{
  flake.nixosConfigurations = lib.mapAttrs (
    hostName: hostConfig:
    let
      inherit (hostConfig) system;
      customLib = mkCustomLib system;
    in
    lib.nixosSystem {
      inherit system;

      modules = [
        ../manifests/nixos-modules.nix
        ../hosts/${hostName}
      ];

      specialArgs = {
        inherit inputs;
        lib = customLib;
      };
    }
  ) constants.hosts;
}
