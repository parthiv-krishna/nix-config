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
  };
  # TODO: allow home-manager config to be used outside of NixOS
  home-manager = {
    extraSpecialArgs = { inherit helpers inputs; };
    users = {
      parthiv = import (helpers.relativeToRoot "home/parthiv/${config.networking.hostName}.nix");
    };
  };
}
