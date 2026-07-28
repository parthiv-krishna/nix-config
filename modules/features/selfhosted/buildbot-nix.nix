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

  homepage = {
    category = "Admin:";
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
          pullBased = {
            pollInterval = 60;
            repositories."parthiv-krishna/nix-config" = {
              defaultBranch = "main";
              url = "https://github.com/parthiv-krishna/nix-config.git";
            };
          };
        };

        worker = {
          enable = true;
          workerPasswordFile = secretPath "worker-password";
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
