{
  lib,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  # enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.root.hashedPassword = "*"; # no root password

}
