# Seerr - media requests (new version, for testing)
{ lib }:
let
  stateDir = "/var/lib/media/state/seerr";
  port = 5056;
in
lib.custom.mkSelfHostedFeature {
  name = "seerr";
  subdomain = "request2";
  inherit port;
  statusPath = "/api/v1/status";

  backupServices = [ "seerr.service" ];

  homepage = {
    category = "Media";
    description = "Request media (new)";
    icon = "sh-jellyseerr";
  };

  oidcClient = {
    redirects = [ "/login?provider=sub0.net&callback=true" ];
    customRedirects = [ "http://request2.sub0.net/login?provider=sub0.net&callback=true" ];
    extraConfig = {
      client_name = "Seerr";
      scopes = [
        "openid"
        "email"
        "profile"
        "groups"
      ];
      authorization_policy = "one_factor";
      token_endpoint_auth_method = "client_secret_post";
    };
  };

  persistentDirectories = [
    {
      directory = stateDir;
      user = "seerr";
      group = "seerr";
    }
  ];

  serviceConfig = _cfg: _: {
    services.seerr = {
      enable = true;
      inherit port;
      configDir = stateDir;
    };

    systemd.services.seerr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "seerr";
      Group = "seerr";
      ReadWritePaths = [ stateDir ];
    };

    users.users.seerr = {
      isSystemUser = true;
      group = "seerr";
    };
    users.groups.seerr = { };
  };
}
