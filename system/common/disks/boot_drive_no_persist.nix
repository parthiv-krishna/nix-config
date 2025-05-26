# disko configuration for a boot drive with boot/ESP/swap/root partitions
# the root partition is further subdivided into 2 subvolumes
#   /root    (intended to be wiped on boot by impermanence module)
#   /nix     (holds nix store)
# you will probably want a separate drive setup for /persist (see persist_cached_hdd_array.nix)
# based on https://github.com/vimjoyer/impermanent-setup/blob/main/final/disko.nix

{
  device ? throw "Set this to your disk device, e.g. /dev/sda",
  swapSize ? "8G",
  ...
}:
{
  disko.devices = {
    disk.main = {
      inherit device;
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
    };
  };
}
