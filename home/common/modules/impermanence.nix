# impermanence configuration - automatically enabled on NixOS hosts, disabled on standalone

{
  config,
  inputs,
  lib,
  ...
}:
{
  # wrapper around persistence options that works whether or not impermanence is setup
  # will be ignored on standalone home-managersystems
  options.custom.persistence = {
    directories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of directories to persist. Only applied on NixOS systems with impermanence.";
    };

    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of files to persist. Only applied on NixOS systems with impermanence.";
    };
  };

  # only enable impermanence and apply the collected persistence on NixOS hosts
  # using if-then-else so that home.persistence is not evaluated on standalone systems
  config =
    if (!config.targets.genericLinux.enable) then
      {
        imports = [
          inputs.impermanence.nixosModules.home-manager.impermanence
        ];

        home.persistence."/persist/home/parthiv" = {
          directories = [
            ".ssh"
          ] ++ config.custom.persistence.directories;
          inherit (config.custom.persistence) files;
          allowOther = true;
        };
      }
    else
      { };
}
