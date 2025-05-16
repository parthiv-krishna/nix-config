{
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

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

}
