# disko configuration for a 2-drive setup, useful when boot drive is small
# 1. boot drive with boot/ESP/swap/root partitions
# the root partition is further subdivided into 2 subvolumes
#   /root    (intended to be wiped on boot by impermanence module)
#   /persist (keeps explicitly-declared persistent state)
# based on https://github.com/vimjoyer/impermanent-setup/blob/main/final/disko.nix
# 2. separate drive with /nix

{
  mainDevice ? throw "Set this to your disk device, e.g. /dev/sda",
  nixDevice ? throw "Set this to your disk device, e.g. /dev/sda",
  swapSize ? "1G",
  ...
}:
{
  disko.devices = {
    disk.main = {
      device = mainDevice;
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
    lvm_vg = {
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

                "/persist" = {
                  mountOptions = [
                    "subvol=persist"
                    "noatime"
                  ];
                  mountpoint = "/persist";
                };
              };
            };
          };
        };
      };
    };
    disk.nix = {
      device = nixDevice;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          nix = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/nix";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}
