# sops configuration - automatically enabled on NixOS hosts, disabled on standalone

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (!config.targets.genericLinux.enable) {
    imports = [
      inputs.sops-nix.homeManagerModules.sops
    ];

    sops = {
      age.keyFile = "/home/parthiv/.age/parthiv.age";
      defaultSopsFile = "${inputs.nix-config-secrets}/${config.networking.hostName}.yaml";
      validateSopsFiles = false;

      secrets = {
        # compute SSH private key from sops secret
        "sshKeys/parthiv".path = "/home/parthiv/.ssh/id_ed25519";
      };
    };

    home = {
      packages = with pkgs; [
        sops
      ];
      sessionVariables = {
        SOPS_AGE_KEY_FILE = "/home/parthiv/.age/parthiv.age";
      };
    };

    custom.persistence.directories = [
      ".age"
    ];
  };
}
