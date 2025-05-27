# Mounts an array of HDDs with btrfs
# setup for mergerfs/snapraid with data and parity disks

{
  dataDevices ? throw "Set this to a list of data devices to mount",
  parityDevices ? throw "Set this to a list of parity devices to mount",
  cacheDevice ? throw "Set this to a cache device to mount",
  lib,
  ...
}:

{
  disko.devices = {
    disk = builtins.listToAttrs (
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
                    type = "filesystem";
                    format = "btrfs";
                    mountpoint = "/array/disk/data${toString i}";
                  };
                };
              };
            };
          };
        }
      ) dataDevices)
      ++

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
                      mountpoint = "/array/disk/parity${toString i}";
                    };
                  };
                };
              };
            };
          }
        ) parityDevices)
      ++ [
        {
          name = "cache";
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
                    type = "filesystem";
                    format = "btrfs";
                    mountpoint = "/array/disk/cache";
                  };
                };
              };
            };
          };
        }
      ]
    );
  };
}
