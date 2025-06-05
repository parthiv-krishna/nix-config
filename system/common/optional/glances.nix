{ config, ... }:
let
  port = config.constants.ports.glances;
  # copied from lib/services.nix
  # TODO: refactor
  fqdn = "glances.${config.networking.hostName}.${config.constants.domains.internal}";
  virtualHostConfig = logName: {
    logFormat = ''
      output file ${config.services.caddy.logDir}/access-${logName}.log {
        roll_size 10MB
        roll_keep 5
        roll_keep_for 14d
        mode 0640
      }
      level DEBUG
    '';
    extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
      reverse_proxy localhost:${toString port}
    '';
  };
in
{
  services.glances = {
    enable = true;
    # don't open firewall; will be accessed over tailscale
    inherit port;
  };

  services.caddy.virtualHosts.${fqdn} = virtualHostConfig fqdn;
}
