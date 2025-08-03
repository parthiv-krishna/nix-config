{
  lib,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  options.custom.selfhosted = {
    homepageServices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            category = lib.mkOption {
              type = lib.types.str;
              description = "Category for grouping services";
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = "Description of the service";
            };
            icon = lib.mkOption {
              type = lib.types.str;
              description = "Icon identifier for the service";
            };
            name = lib.mkOption {
              type = lib.types.str;
              description = "Service name";
            };
            subdomain = lib.mkOption {
              type = lib.types.str;
              description = "Subdomain for the service";
            };
            hostName = lib.mkOption {
              type = lib.types.str;
              description = "Host name where service runs";
            };
          };
        }
      );
      default = { };
      description = "Metadata for all self-hosted services with homepage entries";
    };

    oidcClients = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            subdomain = lib.mkOption {
              type = lib.types.str;
              description = "Subdomain for the service (required for auto-generating URLs)";
            };
            redirects = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Path segments to append to https://subdomain.domain (required)";
            };
            customRedirects = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Full redirect URIs that don't use the service domain (e.g., app URLs)";
            };
            extraConfig = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Additional OIDC configuration fields";
            };
          };
        }
      );
      default = { };
      description = "OIDC client configurations - auto-generates client_id, client_secret, public, and redirect_uris";
    };

  };
}
