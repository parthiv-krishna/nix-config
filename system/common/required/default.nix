{
  config,
  helpers,
  inputs,
  ...
}:
{
  imports = helpers.scanPaths ./.;

  # enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.root.hashedPassword = "*"; # no root password

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

  system.stateVersion = "24.11";

}
