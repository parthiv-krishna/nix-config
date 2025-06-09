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

  # this version fixes GitSync issues. should be able to switch once 12.1.0 hits nixpkgs
  grafana-nightly = pkgs.stdenv.mkDerivation rec {
    pname = "grafana";
    version = "12.1.0-244117";

    src = pkgs.fetchurl {
      url = "https://dl.grafana.com/oss/release/grafana_12.1.0-244117_244117_linux_arm64.tar.gz";
      sha256 = "sha256-G8de9/By+P3xe0nJCAAGpumwemlyCqCdXqHQsutSMWI=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin $out/share/grafana $out/etc/grafana

      # Copy all files to share directory (this becomes homepath)
      cp -r * $out/share/grafana/

      # Move binary to bin
      mv $out/share/grafana/bin/grafana $out/bin/grafana

      # Ensure proper permissions
      chmod +x $out/bin/grafana

      # Create wrapper with proper homepath
      wrapProgram $out/bin/grafana
    '';

    meta = with pkgs.lib; {
      description = "Grafana nightly build";
      platforms = platforms.linux;
    };
  };
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
        package = grafana-nightly;
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
          "auth.anonymous" = {
            enabled = true;
            org_name = config.constants.domains.public;
            org_role = "Viewer";
          };
          "auth.generic_oauth" = {
            enabled = true;
            name = "${config.constants.domains.public} SSO";
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
            # users are Viewer by default, but can be promoted by admin account
            skip_org_role_sync = true;
            auto_login = false;
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
