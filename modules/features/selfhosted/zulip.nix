# Zulip - team chat
{ lib }:
let
  port = 9080;
in
lib.custom.mkSelfHostedFeature {
  name = "zulip";
  subdomain = "chat";
  inherit port;

  homepage = categories: {
    category = categories.tools;
    description = "Team chat";
    icon = "sh-zulip";
  };

  oidcClient = {
    redirects = [ "/complete/oidc/" ];
    extraConfig = {
      client_name = "Zulip";
      scopes = [
        "openid"
        "profile"
        "email"
      ];
      authorization_policy = "one_factor";
      require_pkce = false;
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      access_token_signed_response_alg = "none";
      userinfo_signed_response_alg = "none";
      token_endpoint_auth_method = "client_secret_basic";
    };
  };

  persistentDirectories = [
    {
      directory = "/var/lib/rabbitmq";
      user = "rabbitmq";
      group = "rabbitmq";
      mode = "0750";
    }
    {
      directory = "/var/lib/redis-zulip";
      user = "redis-zulip";
      group = "redis-zulip";
      mode = "0700";
    }
    {
      directory = "/var/lib/zulip";
      user = "zulip";
      group = "zulip";
      mode = "0750";
    }
  ];

  serviceConfig =
    _cfg:
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      subdomain = "chat";
      publicFqdn = lib.custom.mkPublicFqdn config.constants subdomain;
      secretsRoot = "zulip";
      oidcConfigTemplate = "zulip/oidc-config.json";
      zulipSource = inputs.nix-zulip;
    in
    {
      nixpkgs.overlays = [
        (final: prev: {
          grok-exporter = final.callPackage (zulipSource + "/nix/packages/grok-exporter") { };
          zulip-server = final.callPackage (zulipSource + "/nix/packages/zulip-server") { };
          zulip-prometheus-exporter = final.callPackage (
            zulipSource + "/nix/packages/zulip-prometheus-exporter"
          ) { };

          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (pythonFinal: _pythonPrev: {
              django-bitfield = pythonFinal.callPackage (
                zulipSource + "/nix/packages/python-packages/django-bitfield"
              ) { };
              django-bmemcached = pythonFinal.callPackage (
                zulipSource + "/nix/packages/python-packages/django-bmemcached"
              ) { };
              firebase-admin = pythonFinal.callPackage (
                zulipSource + "/nix/packages/python-packages/firebase-admin"
              ) { };
              jsx-lexer = pythonFinal.callPackage (zulipSource + "/nix/packages/python-packages/jsx-lexer") { };
              loadcredential = pythonFinal.callPackage (
                zulipSource + "/nix/packages/python-packages/loadcredential"
              ) { };
              pydantic-partials = pythonFinal.callPackage (
                zulipSource + "/nix/packages/python-packages/pydantic-partials"
              ) { };
              pyoembed = pythonFinal.callPackage (zulipSource + "/nix/packages/python-packages/pyoembed") { };
              python-binary-memcached = pythonFinal.callPackage (
                zulipSource + "/nix/packages/python-packages/python-binary-memcached"
              ) { };
              python-bsonstream = pythonFinal.callPackage (
                zulipSource + "/nix/packages/python-packages/python-bsonstream"
              ) { };
              talon-core = pythonFinal.callPackage (zulipSource + "/nix/packages/python-packages/talon-core") { };
              uhashring = pythonFinal.callPackage (zulipSource + "/nix/packages/python-packages/uhashring") { };
              xsentinels = pythonFinal.callPackage (zulipSource + "/nix/packages/python-packages/xsentinels") { };
              zulip-api = pythonFinal.callPackage (zulipSource + "/nix/packages/python-packages/zulip-api") { };
              zulip-bots = pythonFinal.callPackage (zulipSource + "/nix/packages/python-packages/zulip-bots") { };
            })
          ];
        })
      ];

      services = {
        zulip = {
          enable = true;
          enablePostgresqlLocally = true;
          host = publicFqdn;

          camoKeyFile = config.sops.secrets."${secretsRoot}/camo_key".path;
          sharedSecretKeyFile = config.sops.secrets."${secretsRoot}/shared_secret".path;
          secretKeyFile = config.sops.secrets."${secretsRoot}/secret_key".path;
          avatarSaltKeyFile = config.sops.secrets."${secretsRoot}/avatar_salt".path;
          rabbitmqPasswordFile = config.sops.secrets."${secretsRoot}/rabbitmq_password".path;

          zulipSettings = {
            EXTERNAL_HOST = publicFqdn;
            ZULIP_ADMINISTRATOR = "admin@${config.constants.domains.public}";
            ZULIP_SERVICE_PUSH_NOTIFICATIONS = false;
            ZULIP_SERVICE_SUBMIT_USAGE_STATISTICS = false;
            REDIS_PORT = 6380;
            AUTHENTICATION_BACKENDS = [
              "zproject.backends.EmailAuthBackend"
              "zproject.backends.GenericOpenIdConnectBackend"
            ];
            SOCIAL_AUTH_OIDC_ENABLED_IDPS = {
              _get_secret = config.sops.templates.${oidcConfigTemplate}.path;
            };
          };
        };

        # Authelia already uses the default 6379.
        redis.servers.zulip.port = lib.mkForce 6380;

        # nix-zulip sets up nginx. Keep this but only bind to
        # localhost so that we can still sit behind the common Caddy.
        nginx.virtualHosts = {
          "127.0.0.1" = {
            listen = lib.mkForce [
              {
                addr = "127.0.0.1";
                # nix-zulip port
                port = 9081;
              }
            ];
          };
          ${publicFqdn} = {
            enableACME = lib.mkForce false;
            forceSSL = lib.mkForce false;
            listen = lib.mkForce [
              {
                addr = "127.0.0.1";
                # Redirected port from Caddy
                inherit port;
              }
            ];
          };
        };
      };

      sops = {
        templates.${oidcConfigTemplate} = {
          content = builtins.toJSON {
            authelia = {
              oidc_url = "${lib.custom.mkPublicHttpsUrl config.constants "login"}";
              display_name = "${config.constants.domains.public} SSO";
              display_icon = null;
              client_id = config.sops.placeholder."${secretsRoot}/client_id";
              secret = config.sops.placeholder."${secretsRoot}/client_secret_orig";
              auto_signup = true;
            };
          };
          owner = "zulip";
          mode = "0400";
        };

        secrets = {
          "${secretsRoot}/camo_key" = { };
          "${secretsRoot}/shared_secret" = { };
          "${secretsRoot}/secret_key" = { };
          "${secretsRoot}/avatar_salt" = { };
          "${secretsRoot}/rabbitmq_password" = { };
          "${secretsRoot}/client_id" = { };
          "${secretsRoot}/client_secret_orig" = { };
        };
      };
    };
}
