# Tailscale - always enabled on NixOS hosts
{ ... }:
{
  services.tailscale.enable = true;
}
