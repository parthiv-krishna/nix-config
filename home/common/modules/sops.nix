# sops configuration - automatically enabled on NixOS hosts, disabled on standalone

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.sops;
in
{
  options.custom.sops = {
    sopsFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to the sops file to use for secrets. Only applied on NixOS systems.";
    };
  };

  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  config = lib.mkIf (!config.targets.genericLinux.enable) {
    sops = {
      age.keyFile = "/persist/home/parthiv/.age/parthiv.age";
      defaultSopsFile = "${inputs.nix-config-secrets}/${cfg.sopsFile}";
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
        SOPS_AGE_KEY_FILE = "/persist/home/parthiv/.age/parthiv.age";
      };
    };

    custom.persistence.directories = [
      ".age"
    ];
  };
}
