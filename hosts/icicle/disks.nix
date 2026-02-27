# disko configuration for a boot drive with boot/ESP/swap/root partitions
# the root partition is further subdivided into 3 subvolumes
#   /root    (intended to be wiped on boot by impermanence module)
#   /persist (keeps explicitly-declared persistent state)
#   /nix     (holds nix store)
# root is encrypted with LUKS with an interactive login password (bitlocker style)
# based on https://github.com/vimjoyer/impermanent-setup/blob/main/final/disko.nix
# encryption setup is based on https://github.com/nix-community/disko/blob/master/example/luks-interactive-login.nix

{
  lib,
  ...
}:
let
  device = "/dev/disk/by-id/nvme-nvme.1c5c-414442394e37303139313037303951304f-5348475033312d32303030474d-00000001";
  swapSize = "40G";
  # during installation, the password file is provided by the user
  # within the configuration, we don't specify it (so we get an interactive password prompt)
  passwordFile = null;
in
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
              type = "luks";
              name = "crypted";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              content = {
                type = "lvm_pv";
                vg = "root_vg";
              };
            }
            // lib.optionalAttrs (passwordFile != null) {
              # provide the password file during installation
              inherit passwordFile;
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
