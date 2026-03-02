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

    home-manager = {
      extraSpecialArgs = {
        inherit inputs;
      };
      sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.nix-colors.homeManagerModules.default
        inputs.nixvim.homeModules.nixvim
      ];
      users.parthiv = {
        home.stateVersion = config.system.stateVersion;
      };
      backupFileExtension = "bak";
    };
  };
}
