# impermanence setup - only enabled on NixOS hosts

{
  config,
  lib,
  ...
}:
{
  imports = lib.flatten [
    (lib.custom.scanPaths ./.)
  ];

  config = lib.mkIf (!config.targets.genericLinux.enable) {
    home.persistence."/persist" = {
      directories = [
        ".ssh"
      ]
      ++ config.custom.persistence.directories;
      inherit (config.custom.persistence) files;
    };
  };
}
