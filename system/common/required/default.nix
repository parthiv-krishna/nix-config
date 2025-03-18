{
  config,
  helpers,
  lib,
  pkgs,
  ...
}:
{
  imports = helpers.scanPaths ./.;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

}
