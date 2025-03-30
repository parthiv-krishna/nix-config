# sops configuration, should be imported to home-manager

{
  helpers,
  hostname,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "/home/parthiv/.age/parthiv.age";
    defaultSopsFile = helpers.relativeToRoot "secrets.yaml";
    validateSopsFiles = false;

    secrets = {
      # compute SSH private key from sops secret
      "${hostname}/sshKeys/parthiv".path = "/home/parthiv/.ssh/id_ed25519";
    };
  };

  home = {
    packages = with pkgs; [
      sops
    ];
    sessionVariables = {
      SOPS_AGE_KEY_FILE = "/home/parthiv/.age/parthiv.age";
    };
    # persist age keys
    persistence."/persist/home/parthiv" = {
      directories = [
        ".age"
      ];
    };
  };

}
