# Vaultwarden - Bitwarden-compatible password manager
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "vaultwarden";
  subdomain = "password";
  port = 8222;

  backupServices = [ "vaultwarden.service" ];

  homepage = {
    category = "Tools";
    description = "Password manager";
    icon = "sh-vaultwarden";
    status = "/alive";
  };

  oidcClient = {
    redirects = [ "/identity/connect/oidc-signin" ];
    extraConfig = {
      client_name = "Vaultwarden";
      scopes = [
        "openid"
        "offline_access"
        "profile"
        "email"
      ];
      authorization_policy = "one_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      response_types = [ "code" ];
      grant_types = [
        "authorization_code"
        "refresh_token"
      ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    };
  };

  persistentDirectories = [
    {
      directory = "/var/lib/vaultwarden";
      user = "vaultwarden";
      group = "vaultwarden";
      mode = "0700";
    }
  ];

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    let
      secretsRoot = "vaultwarden";
    in
    {
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        environmentFile = config.sops.templates."vaultwarden/environment".path;
        config = {
          DOMAIN = lib.custom.mkPublicHttpsUrl config.constants "password";
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = true;
          SHOW_PASSWORD_HINT = false;
          # SSO configuration
          SSO_ENABLED = true;
          SSO_ONLY = false;
          SSO_AUTHORITY = lib.custom.mkPublicHttpsUrl config.constants "login";
          SSO_SCOPES = "profile email offline_access";
          SSO_PKCE = true;
          SSO_ROLES_ENABLED = false;
        };
      };

      sops = {
        templates."vaultwarden/environment" = {
          content = ''
            SSO_CLIENT_ID=${config.sops.placeholder."${secretsRoot}/client_id"}
            SSO_CLIENT_SECRET=${config.sops.placeholder."${secretsRoot}/client_secret_orig"}
          '';
          owner = "vaultwarden";
          group = "vaultwarden";
          mode = "0400";
        };

        secrets = {
          "${secretsRoot}/client_id" = {
            owner = "vaultwarden";
            group = "vaultwarden";
            mode = "0400";
          };
          "${secretsRoot}/client_secret_orig" = {
            owner = "vaultwarden";
            group = "vaultwarden";
            mode = "0400";
          };
        };
      };
    };
}
