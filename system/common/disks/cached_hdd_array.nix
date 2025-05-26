# Mounts an array of HDDs with btrfs using dm-cache acceleration
# setup for mergerfs/snapraid with data and parity disks
# Each data disk has a cache partition on the cache device using dm-cache

{
  cacheDevice ? throw "Set this to your cache device, e.g. /dev/nvme0n1",
  cacheSizeGB ? throw "Set this to the total cache size in GB",
  dataDevices ? throw "Set this to a list of data devices to mount",
  parityDevices ? throw "Set this to a list of parity devices to mount",
  lib,
  ...
}:
let
  cacheGBPerDisk = builtins.floor (cacheSizeGB / (builtins.length dataDevices));
  metadataGB = 16;

  # Helper function to create dm-cache setup
  createDmCacheHook = i: ''
    # Wait for devices to be ready
    sleep 2

    echo "Setting up dm-cache for data${toString i}"

    # Use by-id paths for stability
    CACHE_PARTITION="/dev/disk/by-id/${builtins.baseNameOf cacheDevice}-part$((${toString i} + 1))"
    DATA_DEVICE="${builtins.elemAt dataDevices i}"
    DATA_PARTITION="/dev/disk/by-id/$(ls /dev/disk/by-id/ | grep $(basename $DATA_DEVICE) | head -1)-part1"

    echo "Using cache partition: $CACHE_PARTITION"
    echo "Using data partition: $DATA_PARTITION"

    # Debug: Check what's using the devices
    echo "=== DIAGNOSTIC INFO ==="
    echo "Checking if devices are mounted:"
    mount | grep "$CACHE_PARTITION" || echo "Cache partition not mounted"
    mount | grep "$DATA_PARTITION" || echo "Data partition not mounted"

    echo "Checking for existing dm devices:"
    dmsetup ls | grep data${toString i} || echo "No existing dm devices for data${toString i}"

    echo "Checking what processes are using the cache partition:"
    fuser -v "$CACHE_PARTITION" 2>/dev/null || echo "No processes using cache partition"
    lsof "$CACHE_PARTITION" 2>/dev/null || echo "No open files on cache partition"

    echo "Current block device info:"
    lsblk | grep $(basename "$CACHE_PARTITION") || echo "Cache partition not in lsblk"

    # More aggressive cleanup
    echo "=== AGGRESSIVE CLEANUP ==="

    # Force unmount if mounted
    umount "$CACHE_PARTITION" 2>/dev/null || true
    umount "$DATA_PARTITION" 2>/dev/null || true

    # Remove any existing dm devices (more comprehensive)
    for dm_name in data${toString i}-cached data${toString i}-cache data${toString i}-meta; do
      if dmsetup info "$dm_name" >/dev/null 2>&1; then
        echo "Removing existing dm device: $dm_name"
        dmsetup remove "$dm_name" --force 2>/dev/null || true
      fi
    done

    # Kill any processes using the devices
    fuser -km "$CACHE_PARTITION" 2>/dev/null || true
    fuser -km "$DATA_PARTITION" 2>/dev/null || true

    # Wait longer for cleanup
    sleep 3

    # More thorough signature wiping
    echo "Wiping signatures and headers..."
    wipefs -af "$CACHE_PARTITION" 2>/dev/null || true
    wipefs -af "$DATA_PARTITION" 2>/dev/null || true

    # Clear more of the beginning of the device
    dd if=/dev/zero of="$CACHE_PARTITION" bs=1M count=100 2>/dev/null || true
    dd if=/dev/zero of="$DATA_PARTITION" bs=1M count=100 2>/dev/null || true

    # Force kernel to re-read partition table
    partprobe "$CACHE_PARTITION" 2>/dev/null || true
    partprobe "$DATA_PARTITION" 2>/dev/null || true

    # Flush and settle
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    udevadm settle --timeout 60

    # Wait even longer
    sleep 5

    echo "=== ATTEMPTING DM-CACHE CREATION ==="

    # Calculate sizes in sectors (fix the calculation)
    CACHE_SECTORS=$(blockdev --getsz "$CACHE_PARTITION")
    DATA_SECTORS=$(blockdev --getsz "$DATA_PARTITION")
    METADATA_SECTORS=$((${toString metadataGB} * 1024 * 1024 * 2))  # 16GB in 512-byte sectors
    CACHE_DATA_SECTORS=$((CACHE_SECTORS - METADATA_SECTORS))

    echo "Cache sectors: $CACHE_SECTORS, Data sectors: $DATA_SECTORS"
    echo "Metadata sectors: $METADATA_SECTORS, Cache data sectors: $CACHE_DATA_SECTORS"

    # Verify we have enough space
    if [ $CACHE_DATA_SECTORS -le 0 ]; then
      echo "ERROR: Not enough cache space for metadata!"
      exit 1
    fi

    # Create metadata device with error checking
    echo "Creating metadata device..."
    if ! dmsetup create data${toString i}-meta --table "0 $METADATA_SECTORS linear $CACHE_PARTITION 0"; then
      echo "FAILED to create metadata device!"
      echo "Checking device status:"
      ls -la "$CACHE_PARTITION"
      file "$CACHE_PARTITION"
      exit 1
    fi

    # Create cache data device
    echo "Creating cache data device..."
    if ! dmsetup create data${toString i}-cache --table "0 $CACHE_DATA_SECTORS linear $CACHE_PARTITION $METADATA_SECTORS"; then
      echo "FAILED to create cache data device!"
      dmsetup remove data${toString i}-meta 2>/dev/null || true
      exit 1
    fi

    # Wait for devices to appear
    udevadm settle --timeout 30

    # Create the cached device with mq policy
    echo "Creating dm-cache device..."
    if ! dmsetup create data${toString i}-cached --table "0 $DATA_SECTORS cache /dev/mapper/data${toString i}-meta /dev/mapper/data${toString i}-cache $DATA_PARTITION 256 1 writeback mq 0"; then
      echo "FAILED to create cached device!"
      dmsetup remove data${toString i}-cache 2>/dev/null || true
      dmsetup remove data${toString i}-meta 2>/dev/null || true
      exit 1
    fi

    # Wait for device to be ready
    udevadm settle --timeout 30

    echo "Successfully created cached device /dev/mapper/data${toString i}-cached"

    # Create filesystem on the cached device
    if ! blkid "/dev/mapper/data${toString i}-cached" | grep -q 'TYPE='; then
      echo "Creating btrfs filesystem..."
      mkfs.btrfs "/dev/mapper/data${toString i}-cached"
    fi

    # Mount the cached device
    mkdir -p "/mnt/hdd/data${toString i}"
    mount "/dev/mapper/data${toString i}-cached" "/mnt/hdd/data${toString i}" \
      -t btrfs \
      -o noatime,compress=zstd:1

    echo "Successfully mounted /dev/mapper/data${toString i}-cached at /mnt/hdd/data${toString i}"
  '';
in
{
  disko.devices = {
    disk = builtins.listToAttrs (
      # Cache device configuration - split into partitions for each data disk
      [
        {
          name = "cache_${builtins.baseNameOf cacheDevice}";
          value = {
            device = cacheDevice;
            type = "disk";
            content = {
              type = "gpt";
              partitions = builtins.listToAttrs (
                lib.lists.imap0 (i: _: {
                  name = "cache${toString i}";
                  value = {
                    name = "cache${toString i}";
                    size = "${toString cacheGBPerDisk}G";
                    # No content - will be used as raw device for dm-cache
                  };
                }) dataDevices
              );
            };
          };
        }
      ]
      ++
        # Data devices configuration - simple partitions, no LVM
        (lib.lists.imap0 (
          i: device:
          let
            name = "data_${builtins.baseNameOf device}";
          in
          {
            inherit name;
            value = {
              inherit device;
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  data = {
                    name = "data${toString i}";
                    size = "100%";
                    # No content - will be used as raw device for dm-cache
                  };
                };
              };
              # Set up dm-cache after disk is created
              postCreateHook = createDmCacheHook i;
            };
          }
        ) dataDevices)
      ++
        # Parity devices configuration - simple btrfs mounts (unchanged)
        (lib.lists.imap0 (
          i: device:
          let
            name = "parity_${builtins.baseNameOf device}";
          in
          {
            inherit name;
            value = {
              inherit device;
              type = "disk";
              content = {
                type = "gpt";
                partitions = {
                  parity = {
                    name = "parity${toString i}";
                    size = "100%";
                    content = {
                      type = "filesystem";
                      format = "btrfs";
                      mountpoint = "/hdd/parity${toString i}";
                      mountOptions = [
                        "noatime"
                        "compress=zstd:1"
                      ];
                    };
                  };
                };
              };
            };
          }
        ) parityDevices)
    );
  };
}
