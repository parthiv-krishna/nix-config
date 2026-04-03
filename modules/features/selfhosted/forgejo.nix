# Forgejo - Git repository hosting
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "forgejo";
  subdomain = "git";
  port = 3001;
  statusPath = "/api/healthz";

  backupServices = [ "forgejo.service" ];

  homepage = {
    category = "Tools";
    description = "Code repositories";
    icon = "sh-forgejo";
  };

  oidcClient = {
    redirects = [ "/user/oauth2/sub0/callback" ];
    extraConfig = {
      client_name = "Forgejo";
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
      directory = "/var/lib/forgejo";
      user = "git";
      group = "git";
      mode = "0700";
    }
  ];

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    let
      subdomain = "git";
      sshPort = 2222;
      user = "git";
      group = user;
      stateDir = "/var/lib/forgejo";
      mkPublicHttpsUrl = lib.custom.mkPublicHttpsUrl config.constants;
    in
    {
      services.forgejo = {
        enable = true;
        inherit user group;
        dump.enable = true;
        lfs.enable = true;

        settings = {
          server = {
            HTTP_PORT = 3001;
            DOMAIN = lib.custom.mkPublicFqdn config.constants subdomain;
            LANDING_PAGE = "explore";
            ROOT_URL = mkPublicHttpsUrl subdomain;
            SSH_DOMAIN = lib.custom.mkPublicFqdn config.constants subdomain;
            SSH_USER = user;
            SSH_PORT = sshPort;
          };
          service = {
            DISABLE_REGISTRATION = false;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
          };
          oauth2_client = {
            ENABLE_AUTO_REGISTRATION = true;
            ACCOUNT_LINKING = "login";
          };
          session = {
            COOKIE_SECURE = true;
          };
        };
      };

      # Auto configure OIDC if needed
      systemd.services.forgejo.preStart =
        let
          providerName = "sub0";
        in
        lib.mkAfter ''
          OIDC_CLIENT_ID="$(tr -d '\r\n' < ${
            config.sops.secrets."authelia/identity_providers/oidc/clients/forgejo/client_id".path
          })"
          OIDC_CLIENT_SECRET="$(tr -d '\r\n' < ${
            config.sops.secrets."authelia/identity_providers/oidc/clients/forgejo/client_secret_orig".path
          })"

          auth_sources="$(${lib.getExe config.services.forgejo.package} admin auth list)"
          auth_id=""
          while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*([0-9]+)[[:space:]]+${providerName}([[:space:]]|$) ]]; then
              auth_id="''${BASH_REMATCH[1]}"
              break
            fi
          done <<< "$auth_sources"

          if [[ -z "$auth_id" ]]; then
            ${lib.getExe config.services.forgejo.package} admin auth add-oauth \
              --provider=openidConnect \
              --name=${providerName} \
              --key="$OIDC_CLIENT_ID" \
              --secret="$OIDC_CLIENT_SECRET" \
              --auto-discover-url="${mkPublicHttpsUrl "login"}/.well-known/openid-configuration" \
              --scopes='openid email profile groups'
          fi
        '';

      sops.secrets."authelia/identity_providers/oidc/clients/forgejo/client_id" = {
        group = user;
        mode = "0440";
      };

      sops.secrets."authelia/identity_providers/oidc/clients/forgejo/client_secret_orig" = {
        owner = user;
        mode = "0400";
      };

      users.users.${user} = {
        isSystemUser = true;
        inherit group;
        home = stateDir;
        useDefaultShell = true;
      };
      users.groups.${group} = { };

      services.openssh.ports = [ sshPort ];

      networking.firewall.allowedTCPPorts = [ sshPort ];
    };
}
