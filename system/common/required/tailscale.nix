# tailscale client configuration

{
  config,
  ...
}:
let
  secretName = "${config.networking.hostName}/tailscale/key";
in
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.${secretName}.path;
    extraUpFlags = [ "--ssh" ];
  };

  sops.secrets.${secretName} = { };

  # persist tailscale state
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/tailscale"
    ];
  };
}
