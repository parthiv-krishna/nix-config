{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  port = 5006;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "actual";
  host = hosts.nimbus;
  inherit port;
  homepage = {
    category = config.constants.homepage.categories.tools;
    description = "Budgeting";
    icon = "sh-actual-budget";
  };
  oidcClient = {
    redirects = [ "/openid/callback" ];
    extraConfig = {
      client_name = "Actual";
      scopes = [
        "email"
        "groups"
        "openid"
        "profile"
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

  persistentDirectories = [ "/var/lib/private/actual" ];
  serviceConfig = {
    services.actual = {
      enable = true;
      settings = {
        inherit port;
      };
    };

  };
}
