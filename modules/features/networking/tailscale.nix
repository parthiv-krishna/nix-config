# Tailscale VPN client feature - system-only
{ lib }:
lib.custom.mkFeature {
  path = [ "networking" "tailscale" ];

  systemConfig = cfg: { config, ... }: let
    secretName = "tailscale/key";
  in {
    services.tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.${secretName}.path;
      extraUpFlags = [ "--ssh" ];
    };

    sops.secrets.${secretName} = { };

    # tailscale integrates with systemd-resolved
    services.resolved = {
      enable = true;
      settings.Resolve.FallbackDNS = [
        # quad9
        "9.9.9.9"
        "149.112.112.112"
      ];
    };

    # persist tailscale state
    environment.persistence."/persist/system" = {
      directories = [
        "/var/lib/tailscale"
      ];
    };
  };
}
