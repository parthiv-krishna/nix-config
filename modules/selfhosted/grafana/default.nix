{
  config,
  lib,
  pkgs,
  ...
}:
let
  subdomain = "stats";
  domain = "${subdomain}.${config.constants.domains.public}";
  autheliaDomain = "auth.${config.constants.domains.public}";
  secretsRoot = "authelia/identity_providers/oidc/clients/grafana";
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "grafana";
  hostName = "nimbus";
  public = true;
  protected = true;
  inherit subdomain;
  serviceConfig = lib.mkMerge [
    {
      environment.systemPackages = with pkgs; [
        grafana-image-renderer
      ];

      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_port = config.constants.ports.grafana;
            root_url = "https://${domain}";
            inherit domain;
            enable_gzip = true;
          };
          feature_toggles = {
            provisioning = true;
            kubernetesDashboards = true;
            apiserver = true;
          };
          "auth.generic_oauth" = {
            enabled = true;
            name = "sub0.net SSO";
            icon = "signin";
            client_id = "$__file{${config.sops.secrets."${secretsRoot}/client_id".path}}";
            client_secret = "$__file{${config.sops.secrets."${secretsRoot}/client_secret_orig".path}}";
            scopes = "openid profile email groups";
            empty_scopes = false;
            auth_url = "https://${autheliaDomain}/api/oidc/authorization";
            token_url = "https://${autheliaDomain}/api/oidc/token";
            api_url = "https://${autheliaDomain}/api/oidc/userinfo";
            login_attribute_path = "preferred_username";
            groups_attribute_path = "groups";
            name_attribute_path = "name";
            use_pkce = true;
            # admin group becomes grafana Admin, grafana group becomes grafana Editor, and everyone else is a grafana Viewer
            role_attribute_path = "contains(groups, 'admin') && 'Admin' || contains(groups, 'grafana') && 'Editor' || 'Viewer'";
            role_attribute_strict = true;
            allow_assign_grafana_admin = true;
            skip_org_role_sync = false;
            auto_login = false;
          };
          log = {
            format = "console";
            level = "debug";
          };
        };
      };

      sops.secrets = {
        "${secretsRoot}/client_id" = {
          # authelia owns, but grafana should be able to access the client id
          group = "grafana";
          mode = "0440";
        };
        "${secretsRoot}/client_secret_orig" = {
          owner = "grafana";
        };
      };
    }
    (lib.custom.mkPersistentSystemDir {
      directory = config.services.grafana.dataDir;
      user = "grafana";
      group = "grafana";
    })
  ];
}
