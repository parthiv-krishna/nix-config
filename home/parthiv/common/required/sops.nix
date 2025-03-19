# sops configuration, should be imported to home-manager

{
  inputs,
  helpers,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "/home/parthiv/.age/parthiv.txt";
    defaultSopsFile = helpers.relativeToRoot "secrets.yaml";
    validateSopsFiles = false;

    secrets = {
      # compute SSH private key from sops secret
      "private_keys/parthiv".path = "/home/parthiv/.ssh/id_ed25519";
    };
  };

}
