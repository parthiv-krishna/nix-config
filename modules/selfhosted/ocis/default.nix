{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) tieredCache;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "ocis";
  hostName = "midnight";
  subdomain = "drive";
  public = true;
  protected = false;
  serviceConfig = {
    unfree.allowedPackages = [
      "ocis_5-bin"
    ];

    services.ocis = {
      enable = true;
      address = "127.0.0.1";
      port = config.constants.ports.ocis;
      url = "https://drive.sub0.net";

      # Use custom data directory in tiered cache
      configDir = "${tieredCache.cachePool}/ocis/config";

      # Use environment file for secrets
      environmentFile = config.sops.templates.ocis-environment.path;

      # Configure the environment for oCIS
      environment = {
        OCIS_INSECURE = "false";
        OCIS_LOG_LEVEL = "info";

        # Disable TLS for HTTP services (Caddy handles TLS)
        OCIS_HTTP_TLS_ENABLED = "false";
        OCIS_URL = "https://drive.sub0.net";

        WEB_UI_CONFIG_SERVER = "https://drive.sub0.net";
        WEB_OIDC_AUTHORITY = "https://drive.sub0.net";

        # Proxy settings - tell oCIS it's behind a reverse proxy
        PROXY_TLS = "false";
        PROXY_INSECURE_BACKEND = "true";
      };
    };

    # Mount the oCIS data directory to the tiered cache so we can keep using ProtectSystem=strict
    systemd.mounts = [
      {
        where = "/var/lib/ocis";
        what = "${tieredCache.cachePool}/ocis";
        type = "bind";
        options = "bind";
      }
    ];

    # TODO: configure everything else
    sops = {
      templates.ocis-environment.content = ''
        JWT_SECRET=${config.sops.placeholder."ocis/jwt_secret"}
      '';
      secrets."ocis/jwt_secret" = {
        owner = "ocis";
        group = "ocis";
      };
    };
  };
}
