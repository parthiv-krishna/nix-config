# Kasm Workspaces - virtual machines
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "kasm";
  subdomain = "vm";
  port = 4443;
  statusPath = "/api/__healthcheck";

  homepage = {
    category = "Tools";
    description = "Virtual machines";
    icon = "sh-kasm-workspaces";
  };

  oidcClient = {
    redirects = [ "/api/oidc_callback" ];
    extraConfig = {
      client_name = "Kasm";
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      authorization_policy = "one_factor";
      require_pkce = false;
      pkce_challenge_method = "";
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    };
  };

  persistentDirectories = [ "/var/lib/kasmweb" ];

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    {
      services.kasmweb = {
        enable = true;
        listenAddress = "0.0.0.0";
        listenPort = 4443;
      };

      custom.features.meta.unfree.allowedPackages = [ "kasmweb" ];

      # Override caddy virtualHosts - kasm uses self-signed cert
      services.caddy.virtualHosts =
        let
          fixedConfigForKasm = ''
            tls {
              dns cloudflare {env.CF_API_TOKEN}
            }
            reverse_proxy localhost:4443 {
              transport http {
                  tls_insecure_skip_verify
              }
              header_up X-Forwarded-Port "443"
              header_up X-Forwarded-Proto "https"
              header_up Host {host}
              header_up X-Real-IP {remote}
              header_up X-Forwarded-For {remote}
            }
          '';
        in
        {
          ${lib.custom.mkPublicFqdn config.constants "vm"}.extraConfig = lib.mkForce fixedConfigForKasm;
          ${lib.custom.mkInternalFqdn config.constants "vm" config.networking.hostName}.extraConfig =
            lib.mkForce fixedConfigForKasm;
        };
    };
}
