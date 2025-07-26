{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (config.constants) domains;
in
{
  imports = lib.custom.scanPaths ./.;

  options.custom.selfhosted = lib.mkOption {
    type = types.attrsOf (
      types.submodule (
        {
          name,
          config,
          options,
          ...
        }:
        {
          options = {
            enable = lib.mkEnableOption "this service";
            hostName = lib.mkOption {
              type = types.str;
            };
            hostNames = lib.mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
            };
            subdomain = lib.mkOption {
              type = types.str;
              default = name;
            };
            public = lib.mkOption {
              type = types.bool;
              default = false;
            };
            protected = lib.mkOption {
              type = types.bool;
              default = true;
            };
            port = lib.mkOption {
              type = types.port;
            };
            serviceConfig = lib.mkOption {
              type = types.anything;
              default = { };
            };
            homepageCategory = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            persistentDirs = lib.mkOption {
              type = types.listOf (
                types.either types.str (
                  types.submodule {
                    options = {
                      directory = lib.mkOption { type = types.str; };
                      user = lib.mkOption {
                        type = types.str;
                        default = "root";
                      };
                      group = lib.mkOption {
                        type = types.str;
                        default = "root";
                      };
                      mode = lib.mkOption {
                        type = types.str;
                        default = "0700";
                      };
                    };
                  }
                )
              );
              default = [ ];
            };
            fqdn = {
              public = lib.mkOption {
                type = types.str;
                readOnly = true;
                default = "${config.subdomain}.${domains.public}";
              };
              internal = lib.mkOption {
                type = types.str;
                readOnly = true;
                default = "${config.subdomain}.${config.hostName}.${domains.internal}";
              };
            };
          };
        }
      )
    );
    default = { };
  };
}
