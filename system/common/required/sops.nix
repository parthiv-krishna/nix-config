{
  helpers,
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = helpers.relativeToRoot "secrets.yaml";
    validateSopsFiles = false;

    age = {
      # if key not present at keyFile, automatically generate from ssh key
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };

    secrets = {
      parthiv-password = { };
    };
  };
}
