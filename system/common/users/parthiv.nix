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

  # TODO: allow home-manager config to be used outside of NixOS
  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      hostname = config.networking.hostName;
    };
    users = {
      parthiv = import (lib.custom.relativeToRoot "home/parthiv/${config.networking.hostName}.nix");
    };
  };
}
