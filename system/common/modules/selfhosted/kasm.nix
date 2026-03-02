{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  port = 4443;
  subdomain = "vm";
  host = hosts.midnight;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "kasm";
  inherit host port subdomain;
  homepage = {
    category = config.constants.homepage.categories.tools;
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

  serviceConfig = {
    services.kasmweb = {
      enable = true;
      listenAddress = "0.0.0.0";
      listenPort = port;
    };

    custom.features.meta.unfree.allowedPackages = [ "kasmweb" ];

    services.caddy.virtualHosts =
      let
        # kasm exposes itself over https using a self-signed cert
        fixedConfigForKasm = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
          }
          reverse_proxy localhost:${toString port} {
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
        ${lib.custom.mkPublicFqdn config.constants subdomain}.extraConfig = lib.mkForce fixedConfigForKasm;
        ${lib.custom.mkInternalFqdn config.constants subdomain host.name}.extraConfig =
          lib.mkForce fixedConfigForKasm;
      };
  };
}
