{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "restic"
  ];

  systemConfig =
    _cfg:
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      secretRoot = "restic";
      secretPassword = "${secretRoot}/password";
      secretRepository = "${secretRoot}/repository";

      # generate scripts to stop/start services for backups
      # Note: custom.selfhosted is defined in the selfhosted module (not migrated yet)
      # Default to empty list if not defined
      servicesToStop = config.custom.selfhosted.backupServices or [ ];

      stopServicesScript = pkgs.writeShellScript "stop-services-for-backup" ''
        echo "stopping services for backup..."
        ${lib.concatMapStringsSep "\n" (service: ''
          echo "stopping ${service}..."
          systemctl stop ${service} || true
        '') servicesToStop}
        echo "all services stopped."
      '';

      startServicesScript = pkgs.writeShellScript "start-services-after-backup" ''
        echo "starting services after backup..."
        ${lib.concatMapStringsSep "\n" (service: ''
          echo "starting ${service}..."
          systemctl start ${service} || true
        '') servicesToStop}
        echo "all services started."
      '';
    in
    {
      environment.systemPackages = with pkgs; [
        restic
      ];

      services.restic.backups.main = {
        paths = [
          "/persist"
        ];
        passwordFile = config.sops.secrets."${secretPassword}".path;
        repositoryFile = config.sops.secrets."${secretRepository}".path;
        timerConfig = {
          OnCalendar = "11:00"; # 4am PT
          Persistent = true;
        };
        initialize = true;
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 3"
          "--keep-monthly 3"
        ];

        # stop services before backup to prevent database corruption
        backupPrepareCommand = lib.mkIf (servicesToStop != [ ]) ''
          ${stopServicesScript}
        '';

        # restart services after backup completes
        backupCleanupCommand = lib.mkIf (servicesToStop != [ ]) ''
          ${startServicesScript}
        '';
      };

      # trust backup.sub0.net
      programs.ssh.knownHosts = {
        "backup.sub0.net".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
      };

      custom.features.meta.discord-notifiers.notifiers.restic-backups-main.enable = true;

      sops.secrets = {
        "${secretPassword}" = { };
        "${secretRepository}" = { };
      };
    };
}
