{ lib }:
let
  homeManagerConfig = inputs: stateVersion: {
    extraSpecialArgs = {
      inherit inputs;
    };
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.nix-colors.homeManagerModules.default
      inputs.nixvim.homeModules.nixvim
    ];
    users.parthiv = {
      home.stateVersion = stateVersion;
    };
    backupFileExtension = "bak";
  };
in
lib.custom.mkFeature {
  path = [
    "meta"
    "parthiv"
  ];

  systemConfig =
    _cfg:
    { config, inputs, ... }:
    let
      passwordSecretName = "loginPasswords/parthiv";
    in
    {
      # password needs to be generated before users are generated
      sops.secrets."${passwordSecretName}" = {
        neededForUsers = true;
      };

      users.users.parthiv = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."${passwordSecretName}".path;
        extraGroups = [
          "systemd-journal"
          "video"
          "wheel"
        ];
        openssh.authorizedKeys.keys = [
          # parthiv@icicle
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDn4cP5Vjigpv2s3CVWSQc3VlmlnxJqfcYMku3Dwbi2k"
        ];
      };

      home-manager = homeManagerConfig inputs config.system.stateVersion;
    };

  darwinConfig =
    _cfg:
    { inputs, ... }:
    {
      system.primaryUser = "parthiv";
      users.users.parthiv.home = "/Users/parthiv";

      home-manager = homeManagerConfig inputs "24.11";
    };
}
