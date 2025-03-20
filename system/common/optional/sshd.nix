# ssh server configuration

_:

{
  services.openssh = {
    enable = true;
    # require public-key auth
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # allow incoming connections on port 22
  networking.firewall.allowedTCPPorts = [ 22 ];

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
