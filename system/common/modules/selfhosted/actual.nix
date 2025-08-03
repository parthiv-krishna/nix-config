{ config, lib, ... }:
let
  inherit (config.constants) hosts;
  port = 5006;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "actual";
  hostName = hosts.nimbus;
  inherit port;
  public = true;
  protected = false;
  homepage = {
    category = config.constants.homepage.categories.tools;
    description = "Budgeting";
    icon = "sh-actual-budget";
  };
  oidcClient = {
    subdomain = "actual";
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
      token_endpoint_auth_method = "client_secret_basic";
      userinfo_signed_response_alg = "none";
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
