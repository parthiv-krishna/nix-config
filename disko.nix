# disko configuration for a main disk with boot/ESP/swap/root partitions
# the root partition is further subdivided into 3 subvolumes
#   /root    (intended to be wiped on boot by impermanence module)
#   /persist (keeps explicitly-declared persistent state)
#   /nix     (holds nix store) 
# based on https://github.com/vimjoyer/impermanent-setup/blob/main/final/disko.nix

{
  device ? throw "Set this to your disk device, e.g. /dev/sda",
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
            size = "8G";
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
