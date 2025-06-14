{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    inputs.disko.nixosModules.default
    inputs.home-manager.nixosModules.default
    (lib.custom.scanPaths ./.)
  ];

  # core system utils
  environment.systemPackages = with pkgs; [
    curl
    fastfetch
    htop
    pciutils
    powertop
    trash-cli
    unzip
    usbutils
    wget
    zip
  ];

  # enable flakes
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # use cachix
    substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  users.users.root.hashedPassword = "*"; # no root password

}
