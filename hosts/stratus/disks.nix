_: {
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        esp = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
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
          size = "100%";
          content = {
            type = "lvm_pv";
            vg = "root_vg";
          };
        };
      };
    };
  };

  disko.devices.lvm_vg.root_vg = {
    type = "lvm_vg";
    lvs.root = {
      size = "100%FREE";
      content = {
        type = "btrfs";
        extraArgs = [ "-f" ];
        subvolumes = {
          "/root".mountpoint = "/";
          "/persist" = {
            mountpoint = "/persist";
            mountOptions = [
              "subvol=persist"
              "noatime"
            ];
          };
          "/nix" = {
            mountpoint = "/nix";
            mountOptions = [
              "subvol=nix"
              "noatime"
            ];
          };
        };
      };
    };
  };
}
