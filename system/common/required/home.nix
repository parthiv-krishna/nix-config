# parthiv user configuration
{
  config,
  lib,
  inputs,
  ...
}:
let
  passwordSecretName = "loginPasswords/parthiv";
in
{
  # password needs to be generated before users are generated
  sops.secrets."${passwordSecretName}" = {
    neededForUsers = true;
  };

  users.users.parthiv = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets."${passwordSecretName}".path;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # parthiv@icicle
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDn4cP5Vjigpv2s3CVWSQc3VlmlnxJqfcYMku3Dwbi2k"
    ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };
    sharedModules = [
      (lib.custom.relativeToRoot "home/common/modules")
    ];
    users = {
      parthiv = import (lib.custom.relativeToRoot "home/${config.networking.hostName}.nix");
    };
  };
}
