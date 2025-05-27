{
  lib,
  ...
}:
let
  hddDevices = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE"
  ];
  cacheDevice = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_25033U803116";
  cacheMetadataSize = "16G";
  bootDevice = "/dev/disk/by-id/ata-ADATA_SP610_1F1220031635";
  swapSize = "8G";
in
{
  disko.devices = {
    disk =
      {
        # boot drive
        boot = {
          device = bootDevice;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                name = "boot";
                size = "1M";
                type = "EF02";
              };
              esp = {
                name = "ESP";
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  # fix warning about /boot being world-readable
                  mountOptions = [ "umask=0077" ];
                };
              };
              swap = {
                size = swapSize;
                content = {
                  type = "swap";
                  resumeDevice = true;
                };
              };
              root = {
                name = "root";
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "root_vg";
                };
              };
            };
          };
        };

        # cache drive for array0
        cache0 = {
          device = cacheDevice;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              cache = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "cache_vg";
                };
              };
            };
          };
        };
      }

      # hdd array
      // (lib.listToAttrs (
        lib.imap0 (i: device: {
          name = "hdd${toString (i + 1)}";
          value = {
            inherit device;
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                raid = {
                  size = "100%";
                  content = {
                    type = "mdraid";
                    name = "array0";
                  };
                };
              };
            };
          };
        }) hddDevices
      ));

    # raid 5
    mdadm.array0 = {
      type = "mdadm";
      level = 5;
      content = {
        type = "lvm_pv";
        vg = "data_vg";
      };
    };

    lvm_vg = {
      # boot drive LVM setup
      root_vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                };
                "/nix" = {
                  mountOptions = [
                    "subvol=nix"
                    "noatime"
                  ];
                  mountpoint = "/nix";
                };
              };
            };
          };
        };
      };

      # cache drive LVM setup
      cache_vg = {
        type = "lvm_vg";
        lvs = {
          cache_meta = {
            size = cacheMetadataSize;
          };
          cache_data = {
            size = "100%FREE";
          };
        };
      };

      # HDD array LVM setup
      data_vg = {
        type = "lvm_vg";
        lvs = {
          data = {
            size = "100%FREE";
          };
        };
        postCreateHook = ''
          # Wait for all devices to be ready
          udevadm settle

          # Load required kernel modules
          modprobe dm-cache
          modprobe dm-cache-smq

          # Set up dmcache
          echo "Setting up dmcache..."

          # Calculate block sizes (in 512-byte sectors)
          CACHE_DATA_SIZE=$(blockdev --getsz /dev/cache_vg/cache_data)
          DATA_SIZE=$(blockdev --getsz /dev/data_vg/data)

          # Data block size for cache (128KB = 256 sectors)
          DATA_BLOCK_SIZE=256

          echo "Cache data size: $CACHE_DATA_SIZE sectors"
          echo "Data size: $DATA_SIZE sectors"
          echo "Using block size: $DATA_BLOCK_SIZE sectors"

          # Create cached device using dm-cache target directly
          # Format: cache <metadata dev> <cache dev> <origin dev> <block size> <#feature args> [<feature arg>]* <policy> <#policy args> [<policy arg>]*
          dmsetup create cached_data --table "0 $DATA_SIZE cache /dev/cache_vg/cache_meta /dev/cache_vg/cache_data /dev/data_vg/data $DATA_BLOCK_SIZE 1 writethrough default 0"

          # Format the cached device with btrfs
          mkfs.btrfs -f /dev/mapper/cached_data

          echo "dmcache setup complete"
        '';
      };
    };

  };
}
