# Actual Budget - budgeting app
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "actual";
  port = 5006;

  backupServices = [ "actual.service" ];

  homepage = {
    category = "Tools";
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

  serviceConfig = _cfg: _: {
    services.actual = {
      enable = true;
      settings = {
        port = 5006;
      };
    };
  };
}
