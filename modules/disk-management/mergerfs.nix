{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.custom.mergerfs;

  # function to create a mergerfs mount option
  mkMergerfsMountOptions = _mountPoint: mountCfg: [
    "defaults"
    "allow_other"
    "cache.files=partial"
    "category.create=${mountCfg.policy}"
    "moveonenospc=true"
    "dropcacheonclose=true"
    "minfreespace=${mountCfg.minfreespace}"
    "fsname=${mountCfg.fsname}"
  ];

  # function to generate the device string from disk list
  mkMergerfsDeviceList = disks: lib.strings.concatStringsSep ":" disks;

  # get all enabled mergerfs mounts
  enabledMounts = lib.filterAttrs (_: mountCfg: mountCfg.enable) cfg;
in
{
  options.custom.mergerfs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to enable this mergerfs mount";
            };

            disks = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "List of disk paths to merge";
              example = [
                "/dev/sda1"
                "/dev/sdb1"
              ];
            };

            policy = lib.mkOption {
              type = lib.types.str;
              default = "mfs";
              description = "MergerFS creation policy";
              example = "mfs";
            };

            fsname = lib.mkOption {
              type = lib.types.str;
              default = "mergerfs-${name}";
              description = "Filesystem name for the mergerfs mount";
            };

            minfreespace = lib.mkOption {
              type = lib.types.str;
              default = "100G";
              description = "Minimum free space required on a disk for new files";
              example = "100G";
            };
          };
        }
      )
    );
    default = { };
    description = "MergerFS mount configurations";
    example = {
      "/data" = {
        enable = true;
        disks = [
          "/dev/sda1"
          "/dev/sdb1"
        ];
        policy = "mfs";
        minfreespace = "100G";
      };
    };
  };

  config = lib.mkIf (enabledMounts != { }) {
    # add mergerfs package
    environment.systemPackages = with pkgs; [
      mergerfs
    ];

    # generate fileSystems entries for each enabled mergerfs mount
    fileSystems = lib.mapAttrs (mountPoint: mountCfg: {
      device = mkMergerfsDeviceList mountCfg.disks;
      fsType = "fuse.mergerfs";
      options = mkMergerfsMountOptions mountPoint mountCfg;
    }) enabledMounts;
  };
}
