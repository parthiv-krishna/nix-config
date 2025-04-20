{
  config,
  helpers,
  ...
}:
let
  name = "traefik";
  secretName = "${config.networking.hostName}/${name}/environment";
in
{
  imports = [
    (helpers.mkCompose {
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
