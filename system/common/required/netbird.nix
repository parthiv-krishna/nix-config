# netbird client configuration

{
  lib,
  ...
}:
{
  services.netbird.enable = true;

  # give an abs path to fix systemd infinite symlink glitch
  systemd.services.netbird = {
    serviceConfig = {
      StateDirectory = lib.mkForce "/var/lib/netbird";
    };
  };

  # persist netbird state
  environment.persistence."/persist/system" = {
    files = [
      "/var/lib/netbird"
    ];
  };
}
