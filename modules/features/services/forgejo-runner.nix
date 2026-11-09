# Forgejo Runner - Forgejo Actions on the host
{ lib }:
lib.custom.mkFeature {
  path = [
    "services"
    "forgejo-runner"
  ];

  extraOptions = {
    extraLabels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "cache" ];
      description = "Additional labels for jobs to target";
    };

    capacity = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "Number of concurrent jobs";
    };

    timeout = lib.mkOption {
      type = lib.types.str;
      default = "30m";
      description = "Maximum job duration";
    };

    cpuQuota = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "200%";
      description = "systemd CPUQuota for the runner";
    };

    memoryMax = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "2G";
      description = "systemd MemoryMax for the runner";
    };
  };

  systemConfig =
    cfg:
    { config, pkgs, ... }:
    let
      instance = "forgejo";
      inherit (config.networking) hostName;
    in
    lib.mkMerge [
      {
        services.forgejo-runner.instances.${instance} = {
          enable = true;
          secrets.server.connections.default.token_url = config.sops.secrets."forgejo/runner/token".path;
          # Bootstrap actions and private flake inputs; job tools live in dev shells.
          # The native module also supplies gitMinimal.
          hostPackages = with pkgs; [
            bash
            coreutils
            nix
            nodejs
            openssh
          ];
          settings = {
            server.connections.default = {
              url = lib.custom.mkPublicHttpsUrl config.constants "git";
              inherit (config.constants.secrets.forgejo.runners.${hostName}) uuid;
            };
            runner = {
              labels = map (label: "${label}:host") (
                [
                  hostName
                  pkgs.stdenv.hostPlatform.system
                ]
                ++ cfg.extraLabels
              );
              inherit (cfg) capacity timeout;
            };
            cache.enabled = false;
          };
        };

        systemd.services."forgejo-runner-${instance}" = {
          after = lib.optional config.services.forgejo.enable "forgejo.service";
          serviceConfig =
            lib.optionalAttrs (cfg.cpuQuota != null) { CPUQuota = cfg.cpuQuota; }
            // lib.optionalAttrs (cfg.memoryMax != null) { MemoryMax = cfg.memoryMax; };
        };

        sops.secrets."forgejo/runner/token" = {
          owner = "root";
          mode = "0400";
          restartUnits = [ "forgejo-runner-${instance}.service" ];
        };
      }
      (lib.custom.mkPersistentSystemDir {
        directory = "/var/lib/private/forgejo-runner";
      })
    ];
}
