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
      public ? false,
      serviceConfig,
      ...
    }:
    let
      inherit (config.constants) domains proxyHostName;
      inherit (config.constants.services.${name}) port;

      myHostName = config.networking.hostName;
      isTargetHost = myHostName == hostName;
      isPublicServer = myHostName == proxyHostName;
      isTargetPublicServer = hostName == proxyHostName;

      # fully qualified domain names
      fqdn = {
        internal = "${name}.${hostName}.${domains.internal}";
        public = "${name}.${domains.public}";
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
              assertion =
                builtins.hasAttr name config.constants.services
                && builtins.hasAttr "port" config.constants.services.${name};
              message = "Port for service `${name}` is not defined in `config.constants.services.${name}.port`. Please define it in `modules/constants.nix`.";
            }
          ];
        }
        (lib.mkIf isTargetHost serviceConfig)

        # target host caddy configuration. route the internal FQDN to the local port
        (lib.mkIf isTargetHost {
          services.caddy.virtualHosts."${fqdn.internal}" = {
            extraConfig = ''
              tls {
                dns cloudflare {env.CF_API_TOKEN}
              }
              reverse_proxy localhost:${toString port}
            '';
          };
        })

        # public server caddy configuration. route the public FQDN to either local port or internal FQDN
        (lib.mkIf isPublicServer {
          services.caddy.virtualHosts =
            let
              proxyTarget =
                if isTargetPublicServer then
                  "http://localhost:${toString port}" # service is here
                else
                  "https://${fqdn.internal}"; # service is on some other internal location
            in
            # expose service to public internet if enabled
            lib.mkIf public {
              "${fqdn.public}" = {
                # TODO: Add CrowdSec, Authelia, and wake on LAN
                extraConfig = ''
                  tls {
                    dns cloudflare {env.CF_API_TOKEN}
                  }
                  reverse_proxy ${proxyTarget}
                '';
              };
            };
        })
      ];
    };
}
