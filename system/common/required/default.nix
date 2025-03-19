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
  users.users.parthiv = {
    isNormalUser = true;
    initialHashedPassword = "[redacted]";
    extraGroups = [ "wheel" ];
  };
  # TODO: allow home-manager config to be used outside of NixOS
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      parthiv = import (helpers.relativeToRoot "home/parthiv/${config.networking.hostName}.nix");
    };
  };

  system.stateVersion = "24.11";

}
