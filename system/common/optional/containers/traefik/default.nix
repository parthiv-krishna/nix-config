{
  config,
  lib,
  ...
}:
let
  name = "traefik";
  secretName = "${name}/environment";
in
{
  imports = [
    (lib.custom.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  virtualisation.oci-containers.containers."traefik-reverse-proxy" = {
    environmentFiles = [
      config.sops.secrets."${secretName}".path
    ];

  };

  sops.secrets."${secretName}" = { };

  # persist logs and ACME cert
  environment.persistence."/persist/system" = {
    directories = [
      "/var/log/traefik"
    ];
    files = [
      "/var/lib/traefik/acme.json"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80 # HTTP
    443 # HTTPS
  ];

}
