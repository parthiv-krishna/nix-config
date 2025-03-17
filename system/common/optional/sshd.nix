# ssh configuration

{
  ...
}:

{
  # enable sshd and allow connections on port 22
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # move to ssh key auth before opening router to internet

  # persist SSH host keys
  environment.persistence."/persist/system" = {
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
