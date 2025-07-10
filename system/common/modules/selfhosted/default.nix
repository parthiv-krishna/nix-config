{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.selfhosted;
  inherit (lib) types;
in
{
  imports = lib.custom.scanPaths ./.;

  options.custom.selfhosted = lib.mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            enable = lib.mkEnableOption "this service";
            hostName = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
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
            config = lib.mkOption {
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
              };
              internal = lib.mkOption {
                type = types.str;
                readOnly = true;
              };
            };
          };
        }
      )
    );
    default = { };
  };

  config = {
    custom.selfhosted = lib.mapAttrs (
      _name: service:
      let
        hostName = if service.hostName != null then service.hostName else null;
      in
      {
        fqdn = {
          public = "${service.subdomain}.${config.constants.domains.public}";
          internal = "${service.subdomain}.${
            if hostName != null then hostName else "localhost"
          }.${config.constants.domains.internal}";
        };
      }
    ) cfg;

    services = lib.mkMerge (
      lib.mapAttrsToList (
        name: service:
        let
          hostName = if service.hostName != null then service.hostName else null;
          hostNames = if service.hostNames != null then service.hostNames else [ ];
          allHostNames = if hostName != null then hostNames ++ [ hostName ] else hostNames;
        in
        lib.mkIf (service.enable && (builtins.elem config.networking.hostName allHostNames)) (
          lib.custom.mkSelfHostedService {
            inherit (service)
              public
              protected
              port
              ;
            inherit name config lib;
            inherit (config.networking) hostName;
            inherit (service) subdomain;
            serviceConfig = lib.mkMerge [
              service.config
              (lib.mkMerge (
                map (
                  dir:
                  if builtins.isString dir then
                    lib.custom.mkPersistentSystemDir { directory = dir; }
                  else
                    lib.custom.mkPersistentSystemDir dir
                ) service.persistentDirs
              ))
            ];
          }
        )
      ) cfg
    );
  };
}
