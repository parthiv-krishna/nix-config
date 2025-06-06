{
  inputs,
  pkgs,
  system,
  ...
}:
{
  mkCompose =
    { name, src }:
    let
      generated = pkgs.stdenv.mkDerivation {
        inherit name src;
        buildInputs = [ inputs.compose2nix.packages.${system}.default ];

        buildPhase = ''
          mkdir -p build
          compose2nix -project=${name} -inputs=$src/compose.yml -output=compose.nix
        '';

        installPhase = ''
          mkdir -p $out
          cp $src/* $out
          cp compose.nix $out
        '';
      };
    in
    {
      imports = [ "${generated}/compose.nix" ];
    };

  mkPersistentSystemDir =
    {
      directory,
      user ? "root",
      group ? user,
      mode ? "0700",
    }:
    {
      environment.persistence."/persist/system".directories = [
        {
          inherit
            directory
            user
            group
            mode
            ;
        }
      ];
    };

  mkSelfHostedService =
    {
      config,
      lib,
      name,
      hostName,
      subdomain ? name,
      public ? false,
      protected ? true,
      serviceConfig,
    }:
    let
      inherit (config.constants) domains proxyHostName;

      port = config.constants.ports.${name};
      myHostName = config.networking.hostName;
      isTargetHost = myHostName == hostName;
      isPublicServer = myHostName == proxyHostName;
      isTargetPublicServer = hostName == proxyHostName;

      # fully qualified domain names
      fqdn = {
        internal =
          if subdomain == "" then
            "${hostName}.${domains.internal}"
          else
            "${subdomain}.${hostName}.${domains.internal}";
        public = if subdomain == "" then domains.public else "${subdomain}.${domains.public}";
      };
      virtualHostConfig = logName: {
        logFormat = ''
          output file ${config.services.caddy.logDir}/access-${logName}.log {
            roll_size 10MB
            roll_keep 5
            roll_keep_for 14d
            mode 0640
          }
          level DEBUG
        '';
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
          }
          reverse_proxy localhost:${toString port}
        '';
      };
    in
    {
      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion = isTargetHost -> config.services.caddy.enable;
              message = "Caddy must be enabled on host `${myHostName}` since it is the host for self-hosted service `${name}`.";
            }
            {
              assertion = isPublicServer -> config.services.caddy.enable;
              message = "Caddy must be enabled on host `${myHostName}` since it is the public server.";
            }
            {
              assertion = builtins.hasAttr name config.constants.ports;
              message = "Port for service `${name}` is not defined in `config.constants.ports.${name}`. Please define it in `modules/constants.nix`.";
            }
          ];
        }
        (lib.mkIf isTargetHost serviceConfig)

        # target host caddy configuration. route the internal FQDN to the local port
        (lib.mkIf (isTargetHost && !isPublicServer) {
          services.caddy.virtualHosts = {
            # route both internal and public FQDN to the local port
            # this allows for routing from public relay and on local network
            "${fqdn.internal}" = virtualHostConfig fqdn.internal;
            "${fqdn.public}" = virtualHostConfig fqdn.public;
          };
        })

        # public server caddy configuration. route the public FQDN to either local port or internal FQDN
        (lib.mkIf isPublicServer {
          services.authelia.instances.${config.custom.reverse-proxy.autheliaInstanceName}.settings.access_control.rules =
            lib.mkIf public [
              {
                domain_regex = "^${fqdn.public}$";
                policy = if protected then "one_factor" else "bypass";
                subject = lib.mkIf protected [ "group:${name}" ];
              }
            ];
          services.caddy.virtualHosts =
            let
              proxyTarget =
                if isTargetPublicServer then
                  "http://localhost:${toString port}" # service is here
                else
                  "https://${fqdn.internal}"; # service is on some other internal location
            in
            lib.mkMerge [
              # expose service to public internet if enabled
              (lib.mkIf public {
                "${fqdn.public}" = {
                  logFormat = ''
                    output file ${config.services.caddy.logDir}/access-${fqdn.public}.log {
                      roll_size 10MB
                      roll_keep 5
                      roll_keep_for 14d
                      mode 0640
                    }
                    level DEBUG
                  '';
                  extraConfig = ''
                    tls {
                      dns cloudflare {env.CF_API_TOKEN}
                    }
                    import auth
                    reverse_proxy ${proxyTarget}
                  '';
                };
              })
              (lib.mkIf isTargetHost {
                "${fqdn.internal}" = virtualHostConfig fqdn.internal;
              })
            ];
        })
      ];
    };
}
