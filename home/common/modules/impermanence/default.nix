# impermanence setup - only enabled on NixOS hosts

{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.custom.scanPaths ./.)
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  config = lib.mkIf (!config.targets.genericLinux.enable) {
    home.persistence."/persist/home/parthiv" = {
      directories = [
        ".ssh"
      ] ++ config.custom.persistence.directories;
      inherit (config.custom.persistence) files;
      allowOther = true;
    };
  };
}
