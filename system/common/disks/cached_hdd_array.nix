# Mounts an array of HDDs with btrfs
# setup for mergerfs/snapraid with data and parity disks
# Each data disk has a cache partition on the cache device

{
  cacheDevice ? throw "Set this to your cache device, e.g. /dev/nvme0n1",
  cacheSizeGB ? throw "Set this to the total cache size in GB",
  dataDevices ? throw "Set this to a list of data devices to mount",
  parityDevices ? throw "Set this to a list of parity devices to mount",
  lib,
  ...
}:
let
  metadataGBPerDisk = 16;
  cacheGBPerDisk = builtins.floor ((cacheSizeGB - metadataGBPerDisk) / builtins.length dataDevices);
in
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
              partitions = builtins.listToAttrs (
                lib.lists.imap0 (i: _: {
                  name = "cache${toString i}";
                  value = {
                    name = "cache${toString i}";
                    size = "${toString cacheGBPerDisk}G";
                    content = {
                      type = "lvm_pv";
                      vg = "data_vg${toString i}";
                    };
                  };
                }) dataDevices
              );
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

    lvm_vg =
      builtins.listToAttrs
        # Data VGs with cache and metadata
        (
          lib.lists.imap0 (i: _: {
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
                cache = {
                  size = "${toString cacheGBPerDisk}G";
                };
                cache_metadata = {
                  size = "${toString metadataGBPerDisk}G";
                };
              };
            };
          }) dataDevices
        );
  };
}
