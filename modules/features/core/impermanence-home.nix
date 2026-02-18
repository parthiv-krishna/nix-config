# impermanence setup - only enabled on NixOS hosts

{
  config,
  lib,
  options,
  ...
}:
{
  imports = [ ./persistence-options.nix ];

  # skip non-nixos hosts
  config = lib.optionalAttrs (options ? home.persistence) {
    home.persistence."/persist" = {
      directories = [
        ".ssh"
        "Documents"
      ]
      ++ config.custom.persistence.directories;
      inherit (config.custom.persistence) files;
    };
  };
}
