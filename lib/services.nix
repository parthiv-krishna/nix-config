{
  inputs,
  pkgs,
  system,
  ...
}:
let
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
in
{
  inherit mkPersistentSystemDir;

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

  mkSelfHostedService =
    {
      config,
      lib,
      name,
      hostName,
      port,
      subdomain ? name,
      public ? false,
      protected ? true,
      serviceConfig,
      persistentDirectories ? [ ],
      homepage ? null,
      oidcClient ? null,
    }:
    let
      inherit (config.constants) publicServerHost;
      myHostName = config.networking.hostName;
      isTargetHost = myHostName == hostName;
      isPublicServer = myHostName == publicServerHost;
      isTargetPublicServer = hostName == publicServerHost;

      # convert strings to attribute set just providing the directory
      processedPersistentDirs = map (
        dir: if lib.isString dir then { directory = dir; } else dir
      ) persistentDirectories;

      persistentDirConfigs = map mkPersistentSystemDir processedPersistentDirs;

      # fully qualified domain names
      fqdn = {
        internal = lib.custom.mkInternalFqdn config.constants subdomain hostName;
        public = lib.custom.mkPublicFqdn config.constants subdomain;
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
      # generate homepage entry if homepage metadata is provided
      homepageEntry =
        if (homepage != null && public) then
          {
            custom.selfhosted.homepageServices."${name}" = {
              inherit (homepage) category description icon;
              inherit name subdomain hostName;
            };
          }
        else
          { };

      # generate oidc client metadata entry if provided
      oidcEntry =
        if (oidcClient != null) then
          {
            custom.selfhosted.oidcClients."${name}" = oidcClient;
          }
        else
          { };

    in
    {
      config = lib.mkMerge (
        [
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
        ]
        ++ persistentDirConfigs
        ++ [
          homepageEntry
          oidcEntry
        ]
      );
    };
}
