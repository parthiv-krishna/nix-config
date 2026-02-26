# Tailscale feature - system-only
{ lib }:
lib.custom.mkFeature {
  path = [ "meta" "tailscale" ];

  systemConfig = cfg: { ... }: {
    services.tailscale.enable = true;
  };
}
