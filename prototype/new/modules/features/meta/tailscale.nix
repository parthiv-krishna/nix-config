# Tailscale feature - system-only
{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "tailscale"
  ];

  systemConfig =
    _cfg:
    _:
    {
      services.tailscale.enable = true;
    };
}
