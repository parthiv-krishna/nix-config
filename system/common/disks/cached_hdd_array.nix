# Mounts an array of HDDs with btrfs
# setup for mergerfs/snapraid with data and parity disks
# Each data disk has a cache partition on the cache device

{
  cacheDevice ? throw "Set this to your cache device, e.g. /dev/nvme0n1",
  dataDevices ? throw "Set this to a list of data devices to mount",
  parityDevices ? throw "Set this to a list of parity devices to mount",
  lib,
  ...
}:

{
  disko.devices = {
    disk = builtins.listToAttrs (
      # Cache device configuration
      [
        {
          name = builtins.baseNameOf cacheDevice;
          value = {
            device = cacheDevice;
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                cache = {
                  name = "cache";
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
      ]
      ++
        # Data devices configuration
        (lib.lists.imap0 (
          i: device:
          let
            name = builtins.baseNameOf device;
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
                    name = "data";
                    size = "100%";
                    content = {
                      type = "lvm_pv";
                      vg = "data_vg${toString i}";
                    };
                  };
                };
              };
            };
          }
        ) dataDevices)
      ++
        # Parity devices configuration
        (lib.lists.imap0 (
          i: device:
          let
            name = builtins.baseNameOf device;
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
                    name = "parity";
                    size = "100%";
                    content = {
                      type = "filesystem";
                      format = "btrfs";
                      mountpoint = "/hdd/parity${toString i}";
                    };
                  };
                };
              };
            };
          }
        ) parityDevices)
    );

    lvm_vg = builtins.listToAttrs (
      # Cache VG
      [
        {
          name = "cache_vg";
          value = {
            type = "lvm_vg";
            # may need to adjust this section if your cache disk is much smaller than 4TB (or you have many data disks)
            lvs = builtins.listToAttrs (
              (lib.lists.imap0 (i: _: {
                name = "cache${toString i}";
                value = {
                  # -1% to account for metadata, ends up wasting a bit with 4TB cache and 2 data disks
                  size = "${toString (builtins.floor (100 / (builtins.length dataDevices)) - 1)}%VG";
                };
              }) dataDevices)
              ++ (lib.lists.imap0 (i: _: {
                name = "cache_metadata${toString i}";
                value = {
                  size = "16G";
                };
              }) dataDevices)
            );
          };
        }
      ]
      ++
        # Data VGs
        (lib.lists.imap0 (i: _: {
          name = "data_vg${toString i}";
          value = {
            type = "lvm_vg";
            lvs = {
              data = {
                size = "100%FREE";
                content = {
                  type = "filesystem";
                  format = "btrfs";
                  mountpoint = "/hdd/data${toString i}";
                };
              };
            };
          };
        }) dataDevices)
    );
  };
}
