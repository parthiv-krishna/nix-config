# User configuration for parthiv - system-only
# Sets up the parthiv user with home-manager integration
{ lib }:
lib.custom.mkFeature {
  path = [ "meta" "parthiv" ];

  systemConfig = cfg: { config, inputs, lib, ... }: let
    passwordSecretName = "loginPasswords/parthiv";
  in {
    # password needs to be generated before users are generated
    sops.secrets."${passwordSecretName}" = {
      neededForUsers = true;
    };

    users.users.parthiv = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."${passwordSecretName}".path;
      extraGroups = [
        "systemd-journal"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        # parthiv@icicle
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDn4cP5Vjigpv2s3CVWSQc3VlmlnxJqfcYMku3Dwbi2k"
      ];
    };

    # Home-manager is configured at the flake level
    # Features inject their home config via home-manager.sharedModules
    # Host-specific home options are in the host file
    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
      };
      sharedModules = [
        # Import sops-nix for all home-manager users
        inputs.sops-nix.homeManagerModules.sops
        # Import nix-colors for theming
        inputs.nix-colors.homeManagerModules.default
        # Note: impermanence home-manager module is auto-imported by NixOS module
        # Import nixvim
        inputs.nixvim.homeModules.nixvim
      ];
      users.parthiv = {
        home.stateVersion = config.system.stateVersion;
      };
      backupFileExtension = "bak";
    };
  };
}
