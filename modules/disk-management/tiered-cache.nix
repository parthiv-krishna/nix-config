{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.custom.tiered-cache;

  webhookFile = config.sops.secrets.${cfg.webhookSecretName}.path;

  # detailed status webhook script
  detailedWebhookScript = pkgs.writeShellScript "send-detailed-webhook.sh" ''
            set -euo pipefail

            STATUS="$1"
            MESSAGE="$2"
            WEBHOOK_FILE="${webhookFile}"

            if [ ! -f "$WEBHOOK_FILE" ]; then
              echo "Webhook file not found: $WEBHOOK_FILE"
              exit 1
            fi

            WEBHOOK_URL=$(cat "$WEBHOOK_FILE")

            # set emoji based on status
            emoji=""
            case "$STATUS" in
              "success") emoji="✅" ;;
              "error") emoji="❌" ;;
              "info") emoji="ℹ️" ;;
              *) emoji="⚠️" ;;
            esac

            echo "Collecting system status information..."

            # cache usage
            CACHE_USAGE=$(${pkgs.coreutils}/bin/df -h "${cfg.cacheDevice}" | tail -1 | ${pkgs.gawk}/bin/awk '{print $3 "/" $2 " (" $5 ")"}')

            # disk usage for each data and parity device
            DISK_INFO=""
            ${lib.concatStringsSep "\n" (
              map (disk: ''
                            USAGE=$(${pkgs.coreutils}/bin/df -h "${disk}" | tail -1 | ${pkgs.gawk}/bin/awk '{print $3 "/" $2 " (" $5 ")"}')
                            DISK_NAME="${builtins.baseNameOf disk}"
                            if [ -n "$DISK_INFO" ]; then
                              DISK_INFO="$DISK_INFO
                💾 $DISK_NAME: \`$USAGE\`"
                            else
                              DISK_INFO="💾 $DISK_NAME: \`$USAGE\`"
                            fi
              '') (cfg.dataDevices ++ cfg.parityDevices)
            )}

            # snapraid status
            echo "Getting SnapRAID status..."
            SNAPRAID_STATUS=$(${pkgs.snapraid}/bin/snapraid status 2>/dev/null | head -10 || echo "Failed to get SnapRAID status")

            # restic repository information
            echo "Getting restic repository information..."
            RESTIC_INFO=""
            ${lib.concatStringsSep "\n" (
              map (repo: ''
                            echo "Checking restic repository: ${repo}"
                            REPO_SIZE="unknown"
                            if systemctl is-enabled --quiet restic-backups-${repo}.service 2>/dev/null; then
                              # try to get repository size with timeout
                              REPO_SIZE=$(timeout 30 ${pkgs.restic}/bin/restic -r "$(systemctl show restic-backups-${repo}.service -p Environment --value 2>/dev/null | grep -o 'RESTIC_REPOSITORY=[^[:space:]]*' | cut -d= -f2)" stats --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.total_size // "unknown"' || echo "unknown")
                            fi
                            if [ -n "$RESTIC_INFO" ]; then
                              RESTIC_INFO="$RESTIC_INFO
                📦 ${repo}: \`$REPO_SIZE\`"
                            else
                              RESTIC_INFO="📦 ${repo}: \`$REPO_SIZE\`"
                            fi
              '') cfg.resticRepositories
            )}

            if [ -z "$RESTIC_INFO" ]; then
              RESTIC_INFO="📦 No repositories configured"
            fi

            echo "Sending detailed Discord webhook..."

            # build the message content with proper newlines
            DISCORD_MESSAGE="$emoji **Tiered Cache Manager**
    $MESSAGE

    🚀 **Cache Usage:** \`$CACHE_USAGE\`

    💽 **Disk Usage:**
    $DISK_INFO🔄 **SnapRAID Status:**
    \`\`\`
    $SNAPRAID_STATUS
    \`\`\`

    📋 **Backup Repositories:**
    $RESTIC_INFO"

            ${pkgs.curl}/bin/curl -X POST "$WEBHOOK_URL" \
              -H "Content-Type: application/json" \
              -d "{\"content\": $(echo "$DISCORD_MESSAGE" | ${pkgs.jq}/bin/jq -Rs .)}" \
              || echo "Failed to send detailed webhook notification"

            echo "Detailed webhook sent successfully"
  '';

  # cache flush script
  cacheFlushScript = pkgs.writeShellScript "cache-flusher.sh" ''
    set -euo pipefail

    CACHE_DRIVE="${cfg.cacheDevice}"
    BASE_POOL="${cfg.baseMountPoint}"
    MAX_USAGE=${toString cfg.maxCacheUsage}
    WEBHOOK_FILE="${webhookFile}"

    # function to send webhook notification
    send_webhook() {
      status="$1"
      message="$2"
      if [ -f "$WEBHOOK_FILE" ]; then
        WEBHOOK_URL=$(cat "$WEBHOOK_FILE")

        # set emoji based on status
        emoji=""
        case "$status" in
          "success") emoji="✅" ;;
          "error") emoji="❌" ;;
          "info") emoji="ℹ️" ;;
          *) emoji="⚠️" ;;
        esac

        ${pkgs.curl}/bin/curl -X POST "$WEBHOOK_URL" \
          -H "Content-Type: application/json" \
          -d "{\"content\": \"$emoji **Tiered Cache Manager:** $message\"}" \
          || echo "Failed to send webhook notification"
      fi
    }

    echo "Starting cache flush operation..."
    send_webhook "info" "Cache flush started"

    # check for files in cache that are older than base
    OLDER_FILES=()
    while IFS= read -r -d $'\0' cache_file; do
      rel_path="''${cache_file#$CACHE_DRIVE/}"
      base_file="$BASE_POOL/$rel_path"

      if [ -f "$base_file" ]; then
        if [ "$cache_file" -ot "$base_file" ]; then
          OLDER_FILES+=("$rel_path")
        fi
      fi
    done < <(find "$CACHE_DRIVE" -type f -print0)

    if [ ''${#OLDER_FILES[@]} -gt 0 ]; then
      echo "ERROR: Cache contains files older than base pool:"
      printf '%s\n' "''${OLDER_FILES[@]}"
      send_webhook "error" "Cache contains ''${#OLDER_FILES[@]} files older than base pool"
      exit 1
    fi

    # sync all files from cache to base
    echo "Syncing files from cache to base..."
    ${pkgs.rsync}/bin/rsync -axqHAXWESR --preallocate --update "$CACHE_DRIVE/" "$BASE_POOL/" || {
      send_webhook "error" "Cache flush failed during rsync"
      exit 1
    }

    # remove old files if cache usage is too high
    while [ $(${pkgs.coreutils}/bin/df --output=pcent "$CACHE_DRIVE" | grep -v Use | cut -d'%' -f1) -gt $MAX_USAGE ]; do
      FILE=$(find "$CACHE_DRIVE" -type f -printf '%A@ %P\n' | \
             sort | \
             head -n 1 | \
             cut -d' ' -f2-)

      if [ -z "$FILE" ]; then
        echo "No more files to remove from cache"
        break
      fi

      echo "Removing old file from cache: $FILE"
      rm -f "$CACHE_DRIVE/$FILE"
    done

    FINAL_USAGE=$(${pkgs.coreutils}/bin/df --output=pcent "$CACHE_DRIVE" | grep -v Use | cut -d'%' -f1)
    echo "Cache flush completed. Final usage: $FINAL_USAGE%"
    send_webhook "info" "Cache flush completed. Usage: $FINAL_USAGE%"
  '';

  # cache prefetch script
  cachePrefetchScript = pkgs.writeShellScript "cache-prefetcher.sh" ''
    set -euo pipefail

    CACHE_DRIVE="${cfg.cacheDevice}"
    BASE_POOL="${cfg.baseMountPoint}"
    MIN_USAGE=${toString cfg.minCacheUsage}
    WEBHOOK_FILE="${webhookFile}"

    send_webhook() {
      status="$1"
      message="$2"
      if [ -f "$WEBHOOK_FILE" ]; then
        WEBHOOK_URL=$(cat "$WEBHOOK_FILE")

        # set emoji based on status
        emoji=""
        case "$status" in
          "success") emoji="✅" ;;
          "error") emoji="❌" ;;
          "info") emoji="ℹ️" ;;
          *) emoji="⚠️" ;;
        esac

        ${pkgs.curl}/bin/curl -X POST "$WEBHOOK_URL" \
          -H "Content-Type: application/json" \
          -d "{\"content\": \"$emoji **Tiered Cache Manager:** $message\"}" \
          || echo "Failed to send webhook notification"
      fi
    }

    CURRENT_USAGE=$(${pkgs.coreutils}/bin/df --output=pcent "$CACHE_DRIVE" | grep -v Use | cut -d'%' -f1)

    if [ $CURRENT_USAGE -ge $MIN_USAGE ]; then
      echo "Cache usage ($CURRENT_USAGE%) above minimum ($MIN_USAGE%), skipping prefetch"
      return 0
    fi

    echo "Starting cache prefetch operation..."
    send_webhook "info" "Cache prefetch started. Current usage: $CURRENT_USAGE%"

    # find recently accessed files in base pool that aren't in cache
    find "$BASE_POOL" -type f -atime -7 -printf '%A@ %P\n' | \
      sort -nr | \
      while read -r timestamp rel_path; do
        cache_file="$CACHE_DRIVE/$rel_path"
        base_file="$BASE_POOL/$rel_path"

        # skip if already in cache
        [ -f "$cache_file" ] && continue

        # check if we still have space
        USAGE=$(${pkgs.coreutils}/bin/df --output=pcent "$CACHE_DRIVE" | grep -v Use | cut -d'%' -f1)
        [ $USAGE -ge $MIN_USAGE ] && break

        # copy file to cache
        echo "Prefetching: $rel_path"
        mkdir -p "$(dirname "$cache_file")"
        ${pkgs.rsync}/bin/rsync -axqHAXWESR --preallocate "$base_file" "$cache_file"
      done

    FINAL_USAGE=$(${pkgs.coreutils}/bin/df --output=pcent "$CACHE_DRIVE" | grep -v Use | cut -d'%' -f1)
    echo "Cache prefetch completed. Final usage: $FINAL_USAGE%"
    send_webhook "info" "Cache prefetch completed. Usage: $FINAL_USAGE%"
  '';

  # main orchestration script
  tieredCacheScript = pkgs.writeShellScript "tiered-cache-manager.sh" ''
    set -euo pipefail

    WEBHOOK_FILE="${webhookFile}"

    send_webhook() {
      status="$1"
      message="$2"
      if [ -f "$WEBHOOK_FILE" ]; then
        WEBHOOK_URL=$(cat "$WEBHOOK_FILE")

        # set emoji based on status
        emoji=""
        case "$status" in
          "success") emoji="✅" ;;
          "error") emoji="❌" ;;
          "info") emoji="ℹ️" ;;
          *) emoji="⚠️" ;;
        esac

        ${pkgs.curl}/bin/curl -X POST "$WEBHOOK_URL" \
          -H "Content-Type: application/json" \
          -d "{\"content\": \"$emoji **Tiered Cache Manager:** $message\"}" \
          || echo "Failed to send webhook notification"
      fi
    }

    echo "=== Tiered Cache Manager Started ==="
    send_webhook "info" "Tiered cache manager cycle started"

    # step 1: cache flush
    echo "Step 1: Cache flush"
    send_webhook "info" "Running cache flush"
    ${cacheFlushScript} || {
      send_webhook "error" "Tiered cache cycle failed at cache flush step"
      exit 1
    }

    # step 2: cache prefetch
    echo "Step 2: Cache prefetch"
    send_webhook "info" "Running cache prefetch"
    ${cachePrefetchScript} || {
      send_webhook "error" "Tiered cache cycle failed at cache prefetch step"
      exit 1
    }

    # step 3: snapraid sync
    echo "Step 3: SnapRAID sync"
    send_webhook "info" "Running SnapRAID sync"
    ${pkgs.snapraid}/bin/snapraid sync || {
      send_webhook "error" "Tiered cache cycle failed at SnapRAID sync step"
      exit 1
    }

    # step 4: restic backups
    echo "Step 4: Restic backups"
    ${lib.concatStringsSep "\n" (
      map (repo: ''
        echo "Running restic backup: ${repo}"
        send_webhook "info" "Starting restic backup: ${repo}"
        systemctl start restic-backups-${repo}.service || {
          send_webhook "error" "Tiered cache cycle failed at restic backup: ${repo}"
          exit 1
        }
      '') cfg.resticRepositories
    )}

    # send detailed completion status
    echo "=== Tiered Cache Manager Completed ==="
    ${detailedWebhookScript} "success" "Tiered cache manager cycle completed successfully"
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

    maxCacheUsage = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "Maximum cache usage percentage before flushing old files";
    };

    minCacheUsage = lib.mkOption {
      type = lib.types.int;
      default = 70;
      description = "Minimum cache usage percentage target for prefetching";
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
  };

  config = lib.mkIf cfg.enable {
    # assertions
    assertions =
      [
        {
          assertion = cfg.maxCacheUsage > cfg.minCacheUsage;
          message = "maxCacheUsage must be greater than minCacheUsage";
        }
      ]
      ++ (map (repo: {
        assertion = config.services.restic.backups ? ${repo};
        message = "Restic backup '${repo}' specified in tiered-cache but not found in services.restic.backups";
      }) cfg.resticRepositories);

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
      # disable built-in scheduling, we manage it manually
      scrubInterval = "never";
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
        ExecStart = tieredCacheScript;
        Nice = 19;
        IOSchedulingPriority = 7;
        CPUSchedulingPolicy = "batch";
      };
      # ensure all required mounts are available
      after = [ "local-fs.target" ];
      wants = [ "local-fs.target" ];
    };

    sops.secrets.${cfg.webhookSecretName} = { };

  };
}
