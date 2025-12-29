{
  lib,
  ...
}:
{
  options.custom.reverse-proxy = {
    enable = lib.mkEnableOption "Caddy-based reverse proxy";

    cloudflareTokenSecretName = lib.mkOption {
      type = lib.types.str;
      default = "caddy/cloudflare_api_token";
      description = "The name of the Sops secret that holds the Cloudflare API token (e.g., 'cloudflare/api_token').";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Email address for ACME (Let's Encrypt) certificate registration.";
      example = "admin@example.com";
    };
  };
}
