# tinypaas - tiny personal web apps (Go binaries + SQLite) at apps.<domain>/<name>

{ lib }:
let
  port = 8090;
  subdomain = "apps";
in
lib.custom.mkSelfHostedFeature {
  name = "tinypaas";
  inherit subdomain port;
  statusPath = "/_tinypaas/healthz";

  # stop apps so their SQLite databases are snapshotted consistently
  backupServices = [ "tinypaas.service" ];

  extraOptions = {
    allowedGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "admin" ];
      description = "Authelia groups allowed to use the apps. Empty allows any signed-in user.";
    };
  };

  homepage = categories: {
    category = categories.tools;
    description = "Personal apps";
    icon = "mdi-apps";
  };

  oidcClient = {
    redirects = [ "/_tinypaas/callback" ];
    extraConfig = {
      client_name = "Apps";
      scopes = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      authorization_policy = "one_factor";
      require_pkce = true;
      pkce_challenge_method = "S256";
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    };
  };

  persistentDirectories = [
    {
      directory = "/var/lib/tinypaas";
      user = "tinypaas";
      group = "tinypaas";
      mode = "0750";
    }
  ];

  serviceConfig =
    cfg:
    { config, ... }:
    let
      secret = name: config.sops.secrets.${name}.path;
      runner = config.custom.features.services.forgejo-runner;
    in
    lib.mkMerge [
      {
        services.tinypaas = {
          enable = true;
          listenAddress = "127.0.0.1";
          inherit port;
          publicUrl = lib.custom.mkPublicHttpsUrl config.constants subdomain;
          oidc = {
            issuer = lib.custom.mkPublicHttpsUrl config.constants "login";
            clientIdFile = secret "tinypaas/oidc/client_id";
            clientSecretFile = secret "tinypaas/oidc/client_secret";
            inherit (cfg) allowedGroups;
          };
        };

        sops.secrets =
          let
            restart.restartUnits = [ "tinypaas.service" ];
          in
          {
            "tinypaas/oidc/client_id" = restart;
            "tinypaas/oidc/client_secret" = restart;
          };
      }

      # Deploy jobs run on this host's runner and talk to the control socket.
      (lib.mkIf runner.enable {
        custom.features.services.forgejo-runner.extraLabels = [ "tinypaas" ];
        services.forgejo-runner.instances.forgejo.hostPackages = [ config.services.tinypaas.package ];
        systemd.services.forgejo-runner-forgejo.serviceConfig.SupplementaryGroups = [ "tinypaas" ];
      })
    ];
}
