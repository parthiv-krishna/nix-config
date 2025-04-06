{
  ...
}:
{
  imports = [ ./docker-compose.nix ];

  networking.firewall.allowedTCPPorts = [
    43110
  ];

}
