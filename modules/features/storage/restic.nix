{ lib }:
lib.custom.mkFeature {
  path = [
    "storage"
    "restic"
  ];

  extraOptions = {
    backupTime = lib.mkOption {
      type = lib.types.str;
      default = "04:00";
      description = "time to run daily backups";
      example = "03:30";
    };

    snapshotType = lib.mkOption {
      type = lib.types.enum [
        "none"
        "zfs"
        "btrfs"
      ];
      default = "none";
      description = "filesystem snapshot type, should be the fs for /persist";
    };

    excludePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "paths to exclude from backup";
      example = [
        "/var/lib/immich/thumbs"
        "/var/lib/media/library"
      ];
    };
  };

  systemConfig =
    cfg:
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

      snapshotName = "restic-backup";
      backupPath = "/persist.backup";

      # Backup server hostname
      backupHost = "backup.${config.constants.domains.public}";

      inherit (config.custom.features.selfhosted) backupServices;

      createSnapshot = {
        zfs = pkgs.writeShellScript "zfs-create-snapshot" ''
          set -euo pipefail

          DATASET=$(${pkgs.zfs}/bin/zfs list -H -o name /persist 2>/dev/null || echo "")
          if [ -z "$DATASET" ]; then
            echo "ERROR: Could not detect ZFS dataset for /persist"
            exit 1
          fi
          echo "detected ZFS dataset: $DATASET"

          SNAPSHOT="$DATASET@${snapshotName}"

          echo "deleting old snapshot if it exists"
          ${pkgs.util-linux}/bin/umount ${backupPath} 2>/dev/null || true
          if ${pkgs.zfs}/bin/zfs list -H "$SNAPSHOT" &>/dev/null; then
            echo "removing stale ZFS snapshot: $SNAPSHOT"
            ${pkgs.zfs}/bin/zfs destroy "$SNAPSHOT" || true
          fi

          echo "creating ZFS snapshot: $SNAPSHOT"
          ${pkgs.zfs}/bin/zfs snapshot "$SNAPSHOT"

          echo "mounting snapshot at ${backupPath}"
          mkdir -p ${backupPath}
          ${pkgs.util-linux}/bin/mount -t zfs "$SNAPSHOT" ${backupPath}

          echo "snapshot ready at ${backupPath}"
        '';

        btrfs = pkgs.writeShellScript "btrfs-create-snapshot" ''
          set -euo pipefail

          # findmnt returns "device[/subvol]" format, strip the bracket suffix
          DEVICE=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /persist | ${pkgs.gnused}/bin/sed 's/\[.*\]$//')
          if [ -z "$DEVICE" ]; then
            echo "ERROR: Could not find device for /persist"
            exit 1
          fi
          echo "detected device: $DEVICE"

          # FSROOT gives us the subvolume path directly (e.g., /persist)
          SUBVOL=$(${pkgs.util-linux}/bin/findmnt -n -o FSROOT /persist)
          # strip leading slash for path operations
          SUBVOL="''${SUBVOL#/}"
          if [ -z "$SUBVOL" ]; then
            echo "ERROR: Could not determine BTRFS subvolume for /persist"
            exit 1
          fi
          echo "detected subvolume: $SUBVOL"

          BTRFS_ROOT="/mnt/btrfs-root"
          mkdir -p "$BTRFS_ROOT"
          ${pkgs.util-linux}/bin/mount -t btrfs -o subvol=/ "$DEVICE" "$BTRFS_ROOT"

          SNAPSHOT_PATH="$BTRFS_ROOT/${snapshotName}"

          echo "deleting old snapshot if it exists"
          if [ -d "$SNAPSHOT_PATH" ]; then
            echo "removing stale snapshot: $SNAPSHOT_PATH"
            ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$SNAPSHOT_PATH" || true
          fi

          echo "creating BTRFS snapshot: $SNAPSHOT_PATH"
          ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r "$BTRFS_ROOT/$SUBVOL" "$SNAPSHOT_PATH"

          ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT"
          rmdir "$BTRFS_ROOT"

          echo "deleting old snapshot if it exists"
          ${pkgs.util-linux}/bin/umount ${backupPath} 2>/dev/null || true

          echo "mounting snapshot at ${backupPath}"
          mkdir -p ${backupPath}
          ${pkgs.util-linux}/bin/mount -t btrfs -o subvol=/${snapshotName},ro "$DEVICE" ${backupPath}

          echo "snapshot ready at ${backupPath}"
        '';

        none = pkgs.writeShellScript "none-create-snapshot" ''
          set -euo pipefail

          # clean up stale mount from a previous failed run
          ${pkgs.util-linux}/bin/umount ${backupPath} 2>/dev/null || true

          echo "bind mounting /persist at ${backupPath}"
          mkdir -p ${backupPath}
          ${pkgs.util-linux}/bin/mount --bind /persist ${backupPath}

          echo "bind mount ready at ${backupPath}"
        '';
      };

      destroySnapshot = {
        zfs = pkgs.writeShellScript "zfs-destroy-snapshot" ''
          set -euo pipefail

          DATASET=$(${pkgs.zfs}/bin/zfs list -H -o name /persist 2>/dev/null || echo "")
          SNAPSHOT="$DATASET@${snapshotName}"

          echo "unmounting snapshot from ${backupPath}"
          ${pkgs.util-linux}/bin/umount ${backupPath} || true
          rmdir ${backupPath} || true

          echo "destroying ZFS snapshot: $SNAPSHOT"
          ${pkgs.zfs}/bin/zfs destroy "$SNAPSHOT" || true

          echo "snapshot cleanup complete"
        '';

        btrfs = pkgs.writeShellScript "btrfs-destroy-snapshot" ''
          set -euo pipefail

          # findmnt returns "device[/subvol]" format, strip the bracket suffix
          DEVICE=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE ${backupPath} 2>/dev/null | ${pkgs.coreutils}/bin/head -1 | ${pkgs.gnused}/bin/sed 's/\[.*\]$//')

          echo "unmounting snapshot from ${backupPath}"
          ${pkgs.util-linux}/bin/umount ${backupPath} || true
          rmdir ${backupPath} || true

          if [ -n "$DEVICE" ]; then
            BTRFS_ROOT="/mnt/btrfs-root"
            mkdir -p "$BTRFS_ROOT"
            ${pkgs.util-linux}/bin/mount -t btrfs -o subvol=/ "$DEVICE" "$BTRFS_ROOT"

            SNAPSHOT_PATH="$BTRFS_ROOT/${snapshotName}"
            echo "deleting BTRFS snapshot: $SNAPSHOT_PATH"
            ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$SNAPSHOT_PATH" || true

            ${pkgs.util-linux}/bin/umount "$BTRFS_ROOT"
            rmdir "$BTRFS_ROOT"
          else
            echo "WARNING: Could not determine device, skipping snapshot deletion"
          fi

          echo "snapshot cleanup complete"
        '';

        none = pkgs.writeShellScript "none-destroy-snapshot" ''
          set -euo pipefail

          echo "unmounting bind mount from ${backupPath}"
          ${pkgs.util-linux}/bin/umount ${backupPath} || true
          rmdir ${backupPath} || true

          echo "bind mount cleanup complete"
        '';
      };
    in
    {
      environment.systemPackages = with pkgs; [
        restic
      ];

      services.restic.backups.main = {
        paths = [ backupPath ];
        passwordFile = config.sops.secrets."${secretPassword}".path;
        repositoryFile = config.sops.secrets."${secretRepository}".path;
        timerConfig = {
          OnCalendar = cfg.backupTime;
          Persistent = true;
        };
        initialize = true;
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 3"
          "--keep-monthly 3"
        ];

        exclude = map (p: "${backupPath}/system${p}") cfg.excludePaths;

        backupPrepareCommand = ''
          set -euo pipefail

          echo "stopping ${builtins.toString (builtins.length backupServices)} services..."
          ${lib.concatMapStringsSep "\n" (service: ''
            (echo "stopping ${service}..." && systemctl stop ${service} || true) &
          '') backupServices}
          wait
          echo "all services stopped."

          ${createSnapshot.${cfg.snapshotType}}

          echo "verifying ${backupPath}..."
          ENTRIES=$(${pkgs.findutils}/bin/find ${backupPath} -maxdepth 2 -mindepth 1)
          if [ -z "$ENTRIES" ]; then
            echo "ERROR: ${backupPath} appears empty, aborting backup"
            exit 1
          fi
          echo "$ENTRIES"
          echo "verified ${backupPath}: $(echo "$ENTRIES" | wc -l) entries"

          echo "starting ${builtins.toString (builtins.length backupServices)} services..."
          ${lib.concatMapStringsSep "\n" (service: ''
            (echo "starting ${service}..." && systemctl start ${service} || true) &
          '') backupServices}
          wait
          echo "all services started."
        '';

        backupCleanupCommand = ''
          set -euo pipefail

          ${destroySnapshot.${cfg.snapshotType}}

          echo "backup cleanup complete"
        '';
      };

      systemd.services.restic-backups-main = {
        # PrivateTmp creates a mount namespace, which prevents mounts created
        # in ExecStartPre from being visible in ExecStart. Disable both to
        # ensure the snapshot mount persists across service phases.
        serviceConfig.PrivateMounts = lib.mkForce false;
        serviceConfig.PrivateTmp = lib.mkForce false;
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };

      # trust backup server
      programs.ssh.knownHosts = {
        ${backupHost}.publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
      };

      custom.features.meta.discord-notifiers.notifiers.restic-backups-main.enable = true;

      sops.secrets = {
        "${secretPassword}" = { };
        "${secretRepository}" = { };
      };
    };
}
