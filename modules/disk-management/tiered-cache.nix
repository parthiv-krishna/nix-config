{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.custom.tiered-cache;

  webhookFile = config.sops.secrets.${cfg.webhookSecretName}.path;

  cacheFlusher = pkgs.writeShellScript "cache-flush.sh" ''
    set -o errexit
    ${pkgs.rsync}/bin/rsync -avxHAXWE --numeric-ids --info=progress2 ${cfg.cacheDevice}/ ${cfg.baseMountPoint}/
  '';

  webhookSender = pkgs.writeShellScript "send-webhook.sh" ''
    WEBHOOK_URL="$(cat "${webhookFile}")"
    MESSAGE="$1"
    echo "Sending webhook: $MESSAGE"
    ${pkgs.curl}/bin/curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"**Tiered Cache Manager:** $MESSAGE\"}" "$WEBHOOK_URL"

    if [ $? -ne 0 ]; then
      echo "Failed to send webhook"
      exit 1
    fi
  '';

  aiSummary = pkgs.writeShellScript "ai-summary.sh" ''
    DISK_USAGE=$(${pkgs.coreutils}/bin/df -h ${cfg.cacheDevice} ${cfg.baseMountPoint})
    SNAPRAID_STATUS=$(${pkgs.snapraid}/bin/snapraid status)
    # TODO: make this dynamic based on the restic repositories
    RESTIC_STATUS=$(journalctl --unit=restic-backups-digitalocean -n 100 --no-pager)

    PROMPT="
    Below is the last 100 lines of the stdout of the restic backups
    $RESTIC_STATUS

    Below is the output of snapraid status
    $SNAPRAID_STATUS


    Below is the output of df for the cache and base array
    $DISK_USAGE

    You are pretending to be a server named ${config.networking.hostName}, speaking in the first person.
    You just finished a task involving backing up data with snapraid and restic. Provide a status update message that contains the following information:
    - Size of the restic backups
    - State of the snapraid array
    - Disk usage on tiered-cache and tiered-base

    Don't include any information that was not requested or from previous restic backups, as there is a limit of 1000 characters to your answer after thinking."

    echo "$PROMPT"

    # replace newlines with \n, remove thinking tags
    MESSAGE=$(echo $PROMPT | ${pkgs.ollama}/bin/ollama run ${cfg.aiSummary.model} | sed 's/$/\\n/g' | tr -d '\n' | sed 's/<think>.*<\/think>//g')

    ${webhookSender} "$MESSAGE"
  '';

  tieredCacheManager = pkgs.writeShellScript "tiered-cache-manager.sh" ''
    ${webhookSender} "Tiered cache manager started"

    # flush cache
    ${webhookSender} "Flushing cache"
    ${cacheFlusher}

    ${webhookSender} "Syncing snapraid array"
    ${pkgs.snapraid}/bin/snapraid sync

    # backup to restic
    ${webhookSender} "Starting restic backups"
    for repo in ${toString cfg.resticRepositories}; do
      ${webhookSender} "Starting restic backup for $repo"
      systemctl start restic-backups-$repo
    done

    # send ai summary if enabled
    ${lib.optionalString cfg.aiSummary.enable aiSummary}

    ${webhookSender} "Tiered cache manager finished"
  '';
in
{
  options.custom.tiered-cache = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable tiered cache management";
    };

    cacheDevice = lib.mkOption {
      type = lib.types.str;
      description = "Path to the cache device mount point";
      example = "/array/disk/cache";
    };

    dataDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of data device mount points";
      example = [
        "/array/disk/data0"
        "/array/disk/data1"
      ];
    };

    parityDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of parity device mount points";
      example = [ "/array/disk/parity0" ];
    };

    cacheMountPoint = lib.mkOption {
      type = lib.types.str;
      description = "Mount point for cache + data drives mergerfs pool";
    };

    baseMountPoint = lib.mkOption {
      type = lib.types.str;
      description = "Mount point for data drives only mergerfs pool";
    };

    targetCacheUsage = lib.mkOption {
      type = lib.types.int;
      default = 80;
      description = "Target cache usage percentage for flushing/prefetching";
    };

    timerSchedule = lib.mkOption {
      type = lib.types.str;
      default = "07:00";
      description = "Schedule for tiered cache manager";
      example = "daily";
    };

    resticRepositories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of restic repository names to backup";
      example = [
        "local"
        "remote"
      ];
    };

    snapraidExclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/tmp/"
        "/lost+found/"
      ];
      description = "Paths to exclude from SnapRAID protection";
    };

    webhookSecretName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the secret containing the webhook URL for status notifications";
      example = "tiered-cache/webhook";
    };

    aiSummary = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable AI summary";
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "gemma3:4b";
        description = "Model to use for AI summary";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    # assertions
    assertions = map (repo: {
      assertion = config.services.restic.backups ? ${repo};
      message = "Restic backup '${repo}' specified in tiered-cache but not found in services.restic.backups";
    }) cfg.resticRepositories;

    # configure mergerfs mounts
    custom.mergerfs = {
      # cache + data drives (main accessible mount)
      ${cfg.cacheMountPoint} = {
        enable = true;
        disks = [ cfg.cacheDevice ] ++ cfg.dataDevices;
        policy = "ff";
        fsname = "tiered-cache";
      };

      # data drives only (for flushing)
      ${cfg.baseMountPoint} = {
        enable = true;
        disks = cfg.dataDevices;
        policy = "mfs";
        fsname = "tiered-base";
      };
    };

    # configure snapraid
    custom.snapraid = {
      enable = true;
      dataDisks = cfg.dataDevices;
      parityDisks = cfg.parityDevices;
      exclude = cfg.snapraidExclude;
      scrubInterval = "Sun *-*-* ${cfg.timerSchedule}";
    };

    # disable restic timers (we manage them manually)
    systemd.timers = lib.listToAttrs (
      map (repo: {
        name = "restic-backups-${repo}";
        value.enable = false;
      }) cfg.resticRepositories
    );

    # backup base array
    services.restic.backups = lib.listToAttrs (
      map (repo: {
        name = repo;
        value.paths = [ cfg.baseMountPoint ];
      }) cfg.resticRepositories
    );

    # tiered cache manager service
    systemd.services."tiered-cache-manager" = {
      description = "Tiered Cache Manager";
      startAt = cfg.timerSchedule;
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = tieredCacheManager;
        CPUSchedulingPolicy = "batch";
      };
      # ensure all required mounts are available
      after = [ "local-fs.target" ];
      wants = [ "local-fs.target" ];
    };

    sops.secrets.${cfg.webhookSecretName} = { };

  };
}
