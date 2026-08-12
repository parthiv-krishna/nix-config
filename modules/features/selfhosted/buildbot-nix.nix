# Buildbot-nix - Nix-native continuous integration
{ lib }:
let
  subdomain = "ci";
in
lib.custom.mkSelfHostedFeature {
  name = "buildbot-nix";
  inherit subdomain;
  port = 8010;
  statusPath = "/";

  homepage = categories: {
    category = categories.network;
    description = "Nix continuous integration";
    icon = "sh-buildbot";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/buildbot";
      user = "buildbot";
      group = "buildbot";
      mode = "0750";
    }
    {
      directory = "/var/lib/buildbot-worker";
      user = "buildbot-worker";
      group = "buildbot-worker";
      mode = "0750";
    }
    {
      directory = "/var/lib/postgresql";
      user = "postgres";
      group = "postgres";
      mode = "0750";
    }
  ];

  serviceConfig =
    _cfg:
    { config, pkgs, ... }:
    let
      secretsRoot = "buildbot-nix";
      secretPath = name: config.sops.secrets."${secretsRoot}/${name}".path;
    in
    {
      # keep intermediates of builds for cache serving
      nix.settings = {
        keep-derivations = true;
        keep-outputs = true;
      };

      services.buildbot-nix = {
        master = {
          enable = true;
          domain = lib.custom.mkPublicFqdn config.constants subdomain;
          enableNginx = false;
          useHTTPS = true;
          buildSystems = [
            "aarch64-linux"
            "x86_64-linux"
          ];
          evalMaxMemorySize = 6144;
          evalWorkerCount = 2;
          # cross-compilation and large test suites can be slow
          buildMaxSilentTime = 60 * 60 * 12;
          buildTimeout = 60 * 60 * 24;
          workersFile = config.sops.templates."${secretsRoot}/workers.json".path;
          admins = [ "parthiv-krishna" ];
          effects.extraSandboxPaths = [ (secretPath "github-nix-config-push-ssh-key") ];
          github = {
            appId = 4350657;
            appSecretKeyFile = secretPath "github-app-private-key";
            webhookSecretFile = secretPath "github-webhook-secret";
            oauthId = "Iv23lino1OHuGpchbnrb";
            oauthSecretFile = secretPath "github-oauth-secret";
            repoAllowlist = [ "parthiv-krishna/nix-config" ];
            topic = null;
          };
        };

        worker = {
          enable = true;
          workerPasswordFile = secretPath "worker-password";
        };
      };

      # we need polling to fetch changes since we can't receive webhooks from GH
      services.buildbot-master = {
        changeSource = [
          ''
            changes.GitPoller(
              repourl="https://github.com/parthiv-krishna/nix-config",
              branches=True,
              pollInterval=60,
              pollRandomDelayMin=0,
              pollRandomDelayMax=0,
              pollAtLaunch=True,
              category="push",
              project="parthiv-krishna/nix-config",
            )
          ''
        ];
      };

      systemd.services.buildbot-master = {
        # reload, rather than restart, if service is changed
        reloadIfChanged = true;
        serviceConfig = {
          ExecStop = pkgs.writeShellScript "buildbot-finish-jobs" ''
            set -eu

            if ! kill -0 "$MAINPID" 2>/dev/null; then
              exit 0
            fi

            # tell buildbot to stop accepting work and exit after active builds finish.
            kill -USR1 "$MAINPID"
            while kill -0 "$MAINPID" 2>/dev/null; do
              sleep 5
            done
          '';
          TimeoutStopSec = "26h";
        };
      };

      systemd.services.buildbot-worker.environment.GIT_SSH_COMMAND =
        "${pkgs.openssh}/bin/ssh -i ${secretPath "github-nix-config-secrets-read-ssh-key"} -o IdentitiesOnly=yes -o UserKnownHostsFile=${pkgs.writeText "github-known-hosts" "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"}";

      sops.secrets = {
        "${secretsRoot}/worker-password" = { };
        "${secretsRoot}/github-nix-config-secrets-read-ssh-key" = {
          owner = "buildbot-worker";
          mode = "0400";
        };
        "${secretsRoot}/github-nix-config-push-ssh-key" = {
          owner = "buildbot-worker";
          mode = "0400";
        };
        "${secretsRoot}/github-app-private-key" = { };
        "${secretsRoot}/github-webhook-secret" = { };
        "${secretsRoot}/github-oauth-secret" = { };
      };

      sops.templates."${secretsRoot}/workers.json" = {
        content = builtins.toJSON [
          {
            name = config.networking.hostName;
            pass = config.sops.placeholder."${secretsRoot}/worker-password";
            cores = 4;
          }
        ];
        owner = "buildbot";
        mode = "0400";
      };
    };
}
