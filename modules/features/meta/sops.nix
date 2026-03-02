{ lib }:
lib.custom.mkFeature {
  path = [ "meta" "sops" ];

  extraOptions = {
    sopsFile = lib.mkOption {
      type = lib.types.str;
      description = "The YAML file name for sops secrets (e.g., 'icicle.yaml')";
      example = "icicle.yaml";
    };
  };

  systemConfig = cfg: { config, inputs, ... }: {
    sops = {
      defaultSopsFile = "${inputs.nix-config-secrets}/${config.networking.hostName}.yaml";
      validateSopsFiles = false;

      age = {
        # if key not present at keyFile, automatically generate from ssh key
        generateKey = true;
        keyFile = "/var/lib/sops-nix/key.txt";
        # need to point to /persist as persistence setup to /etc/ssh may not be
        # ready when secrets-for-users are computed.
        # https://github.com/Mic92/sops-nix/commit/4c4fb93f18b9072c6fa1986221f9a3d7bf1fe4b6
        sshKeyPaths = [ "/persist/system/etc/ssh/ssh_host_ed25519_key" ];
      };
    };
  };

  homeConfig = cfg: { config, inputs, pkgs, lib, ... }: 
    lib.mkIf (!config.targets.genericLinux.enable) {
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
        packages = [ pkgs.sops ];
        sessionVariables = {
          SOPS_AGE_KEY_FILE = "/persist/home/parthiv/.age/parthiv.age";
        };
      };

      custom.features.meta.impermanence.directories = [ ".age" ];
    };
}
