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
        ../../system/common/modules
        ../../system/${hostName}
      ];

      specialArgs = {
        inherit inputs;
        lib = customLib;
      };
    }
  ) constants.hosts;
}
