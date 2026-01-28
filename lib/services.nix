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
      host,
      port,
      subdomain ? name,
      serviceConfig,
      persistentDirectories ? [ ],
      homepage ? null,
      oidcClient ? null,
      backupServices ? [ ],
    }:
    let
      isTargetHost = config.networking.hostName == host.name;

      # convert strings to attribute set just providing the directory
      processedPersistentDirs = map (
        dir: if lib.isString dir then { directory = dir; } else dir
      ) persistentDirectories;

      persistentDirConfigs = map mkPersistentSystemDir processedPersistentDirs;

      # fully qualified domain names
      fqdn = {
        internal = lib.custom.mkInternalFqdn config.constants subdomain host.name;
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
        if (homepage != null) then
          {
            custom.selfhosted.homepageServices."${name}" = {
              inherit (homepage) category description icon;
              inherit name subdomain;
              hostName = host.name;
            };
          }
        else
          { };

      # generate oidc client metadata entry if provided
      oidcEntry =
        if (oidcClient != null) then
          {
            custom.selfhosted.oidcClients."${name}" = oidcClient // {
              inherit subdomain;
            };
          }
        else
          { };

    in
    {
      config = lib.mkMerge (
        [
          (lib.mkIf isTargetHost serviceConfig)

          # target host caddy configuration. route the public/internal FQDN to the local port
          (lib.mkIf isTargetHost {
            custom.selfhosted.enableReverseProxy = true;
            services.caddy.virtualHosts = {
              # route both internal and public FQDN to the local port
              # this allows for routing from public relay and on local network
              "${fqdn.internal}" = virtualHostConfig fqdn.internal;
              "${fqdn.public}" = virtualHostConfig fqdn.public;
            };
          })

          (lib.mkIf isTargetHost (lib.mkMerge persistentDirConfigs))

          # register services for backup shutdown if on target host and list is not empty
          (lib.mkIf (isTargetHost && backupServices != [ ]) {
            custom.selfhosted.backupServices = backupServices;
          })
        ]
        ++ [
          homepageEntry
          oidcEntry
        ]
      );
    };
}
