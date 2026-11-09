# controlroom - supervises pi coding agents working on my machines over SSH
{ lib }:
let
  port = 8745;
  subdomain = "controlroom";
in
lib.custom.mkSelfHostedFeature {
  name = "controlroom";
  inherit subdomain port;
  statusPath = "/healthz";

  backupServices = [
    "controlroom.service"
    "controlroom-agent.service"
  ];

  extraOptions = {
    allowedGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "admin" ];
      description = "Authelia groups whose members may sign in to controlroom";
    };
  };

  homepage = categories: {
    category = categories.tools;
    description = "Coding agents";
    icon = "mdi-console";
  };

  oidcClient = {
    redirects = [ "/auth/callback" ];
    extraConfig = {
      client_name = "controlroom";
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
    "/var/lib/private/controlroom"
    "/var/lib/controlroom-agent"
  ];

  serviceConfig =
    cfg:
    { config, ... }:
    let
      secret = name: config.sops.secrets.${name}.path;
    in
    {
      services.controlroom = {
        enable = true;
        listenAddress = "127.0.0.1";
        inherit port;
        publicUrl = lib.custom.mkPublicHttpsUrl config.constants subdomain;
        masterKeyFile = secret "controlroom/master_key";
        auth.oidc = {
          issuer = lib.custom.mkPublicHttpsUrl config.constants "login";
          clientIdFile = secret "controlroom/oidc/client_id";
          clientSecretFile = secret "controlroom/oidc/client_secret";
          inherit (cfg) allowedGroups;
        };
        push.vapidPrivateKeyFile = secret "controlroom/vapid_key";

        agent = {
          sandbox = {
            routes = [
              {
                provider = "openai-codex";
                upstream = "https://chatgpt.com";
                allow = [ "POST /backend-api/codex/responses" ];
              }
            ];
            oauth_claims.openai-codex = [ "https://api.openai.com/auth" ];
          };
          pi = {
            models.providers.openai-codex.modelOverrides = {
              "gpt-6.1-sol".contextWindow = 872000;
              "gpt-6-luna".contextWindow = 872000;
              "gpt-6-astra".contextWindow = 872000;
            };
            settings = {
              defaultProvider = "openai-codex";
              defaultModel = "gpt-6.1-sol";
              defaultThinkingLevel = "medium";
              enableInstallTelemetry = false;
              quietStartup = true;
            };
          };
        };
      };

      sops.secrets =
        let
          restart = {
            restartUnits = [ "controlroom.service" ];
          };
        in
        {
          "controlroom/master_key" = restart;
          "controlroom/vapid_key" = restart;
          "controlroom/oidc/client_id" = restart;
          "controlroom/oidc/client_secret" = restart;
        };
    };
}
