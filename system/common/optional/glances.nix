{ config, ... }:
{
  services.glances = {
    enable = true;
    # don't open firewall; will be accessed over tailscale
    port = config.constants.ports.glances;
  };
}
