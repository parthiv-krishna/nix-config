# sops configuration, should be imported to home-manager

{
  inputs,
  helpers,
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
      "private_keys/parthiv".path = "/home/parthiv/.ssh/id_ed25519";
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
