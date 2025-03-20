{
  helpers,
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

  system.stateVersion = "24.11";

}
