# Unified configuration for midnight (home server)

{ lib, ... }:
let
  dataDisks = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
  ];
  parityDisks = [ "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE" ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    # Import selfhosted directly until refactored
    (lib.custom.relativeToRoot "system/common/modules/selfhosted")
  ];

  networking.hostName = "midnight";
  time.timeZone = "Etc/UTC";

  # required for ZFS
  networking.hostId = "746e646d"; # mdnt

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
    };

    features = {
      apps.opencode.enable = true;

      hardware = {
        gpu.intel.enable = true;
        gpu.nvidia = {
          enable = true;
          cudaCapability = "8.6"; # RTX 3060
        };
        seagate-hdd = {
          enable = true;
          disks = dataDisks ++ parityDisks;
        };
        ups.enable = true;
        wake-on-lan = {
          enable = true;
          device = "enp2s0";
        };
      };

      storage = {
        samba.enable = true;
        zfs.enable = true;
      };

      meta = {
        impermanence.rootPartitionPath = "/dev/disk/by-partlabel/ssd-root";
        sops.sopsFile = "midnight.yaml";
      };
    };
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
