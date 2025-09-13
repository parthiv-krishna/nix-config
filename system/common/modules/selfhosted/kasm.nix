{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  port = 4443;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "kasm";
  hostName = hosts.midnight;
  inherit port;
  subdomain = "vm";
  public = false;
  protected = true;
  homepage = {
    category = config.constants.homepage.categories.storage;
    description = "Virtual machines";
    icon = "sh-kasm-workspaces";
  };

  oidcClient = {
    redirects = [ "/api/oidc_callback/" ];
    extraConfig = {
      client_name = "kasm";
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

    unfree.allowedPackages = [ "kasmweb" ];
  };
}
