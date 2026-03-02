# Configuration for midnight (home server)
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
    (lib.custom.relativeToRoot "system/common/modules/selfhosted")
  ];

  networking.hostName = "midnight";
  time.timeZone = "Etc/UTC";

  # required for ZFS
  networking.hostId = "746e646d"; # mdnt

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
    };

    features = {
      apps.opencode.enable = true;

      hardware = {
        gpu = {
          # intel gpu drivers
          intel.enable = true;
          # nvidia drivers
          nvidia = {
            enable = true;
            cudaCapability = "8.6"; # RTX 3060
          };
        };
        # seagate disk management for all drives
        seagate-hdd = {
          enable = true;
          disks = dataDisks ++ parityDisks;
        };
        # UPS monitoring
        ups.enable = true;
        # wake on LAN support
        wake-on-lan = {
          enable = true;
          device = "enp2s0";
        };
      };

      storage = {
        # smb share
        samba.enable = true;
        # zfs-related services
        zfs.enable = true;
      };

      meta = {
        # tell impermanence to wipe our ssd-root partition on boot
        impermanence.rootPartitionPath = "/dev/disk/by-partlabel/ssd-root";
        sops.sopsFile = "midnight.yaml";
      };
    };
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
