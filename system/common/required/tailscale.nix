# tailscale client configuration

{
  lib,
  ...
}:
{
  services.tailscale.enable = true;

  # give an abs path to fix systemd infinite symlink glitch
  systemd.services.tailscale = {
    serviceConfig = {
      StateDirectory = lib.mkForce "/var/lib/tailscale";
    };
  };

  # persist tailscale state
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/tailscale"
    ];
  };
}
