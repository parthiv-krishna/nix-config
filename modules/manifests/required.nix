{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.default
    inputs.home-manager.nixosModules.default

    ../features/core/constants-system.nix
    ../features/core/unfree-system.nix
    ../features/core/discord-notifiers.nix

    ../features/core/auto-upgrade.nix
    ../features/core/impermanence-system.nix
    ../features/core/user-parthiv.nix
    ../features/core/restic.nix
    ../features/core/sops-system.nix
    ../features/core/tailscale.nix
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  users.users.root.hashedPassword = "*";
}
