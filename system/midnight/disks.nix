{
  lib,
  ...
}:
let
  ssd = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_25033U803116";
  hdds = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
  ];
  swapSize = "16G";
  rootSize = "500G";
  l2arcSize = "1T";
in
{
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = ssd;
        content = {
          type = "gpt";
          partitions = {
            boot = {
              label = "boot";
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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
              size = rootSize;
              content = {
                type = "btrfs";
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                  };
                };
              };
            };
            # l2arc: block cache for zdata
            l2arc = {
              size = l2arcSize;
              content = {
                type = "zfs";
                pool = "zdata";
              };
            };
            # special vdev: metadata and small blocks
            special = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zdata";
              };
            };
          };
        };
      };
    }
    // builtins.listToAttrs (
      lib.lists.imap0 (
        i: device:
        let
          name = "hdd${toString i}";
        in
        {
          inherit name;
          value = {
            type = "disk";
            inherit device;
            content = {
              type = "gpt";
              partitions = {
                data = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "zdata";
                  };
                };
              };
            };
          };
        }
      ) hdds
    );
    zpool.zdata = {
      type = "zpool";
      mode = {
        topology = {
          type = "topology";
          vdev = [
            {
              mode = "raidz1";
              members = lib.lists.imap0 (i: _: "hdd${toString i}") hdds;
            }
          ];
          cache = [ "ssd-l2arc" ];
          special = [
            {
              members = [ "ssd-special" ];
            }
          ];
        };
      };
      rootFsOptions = {
        compression = "zstd";
        "com.sun:auto-snapshot" = "true";
      };
      mountpoint = "/";
      datasets = {
        "persist" = {
          type = "zfs_fs";
          # mount at /persist to be compatible with impermanence
          mountpoint = "/persist";
          options = {
            compression = "zstd";
            "special_small_blocks" = "64K";
          };
        };
      };
    };
  };
}
