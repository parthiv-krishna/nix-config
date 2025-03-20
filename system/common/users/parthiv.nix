{
  config,
  helpers,
  inputs,
  ...
}:
{
  sops.secrets.parthiv-password.neededForUsers = true;
  users.users.parthiv = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.parthiv-password.path;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # parthiv@icicle
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDn4cP5Vjigpv2s3CVWSQc3VlmlnxJqfcYMku3Dwbi2k"
    ];
  };
  # TODO: allow home-manager config to be used outside of NixOS
  home-manager = {
    extraSpecialArgs = { inherit helpers inputs; };
    users = {
      parthiv = import (helpers.relativeToRoot "home/parthiv/${config.networking.hostName}.nix");
    };
  };
}
