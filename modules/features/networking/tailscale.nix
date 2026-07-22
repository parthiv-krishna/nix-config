{ lib }:
lib.custom.mkFeature {
  path = [
    "networking"
    "tailscale"
  ];

  extraOptions = {
    isServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If this machine is a server, enable ssh and exit node";
      example = true;
    };
  };

  systemConfig =
    cfg:
    { config, lib, ... }:
    let
      secretName = "tailscale/key";
    in
    lib.mkMerge [
      {
        networking.firewall.trustedInterfaces = [ "tailscale0" ];

        services.tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets.${secretName}.path;
          useRoutingFeatures = lib.mkIf cfg.isServer "server";
          extraUpFlags = lib.mkIf cfg.isServer [
            "--advertise-exit-node"
            "--ssh"
          ];
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
      }
      (lib.custom.mkPersistentSystemDir {
        directory = "/var/lib/tailscale";
        user = "root";
        group = "root";
      })
    ];

  darwinConfig = _cfg: _: {
    services.tailscale.enable = true;
  };
}
