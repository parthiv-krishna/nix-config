# Configuration for midnight (home server)

{
  lib,
  ...
}:
let
  dataDisks = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
  ];
  parityDisks = [ "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE" ];
in
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    ./disks.nix

    # required system modules
    (lib.custom.relativeToRoot "modules/manifests/required.nix")
    (lib.custom.relativeToRoot "modules/manifests/server.nix")
  ];

  networking.hostName = "midnight";

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  time.timeZone = "Etc/UTC";

  # required for ZFS
  networking.hostId = "746e646d"; # mdnt

  custom = {
    # tell impermanence to wipe our ssd-root partition on boot
    impermanence.rootPartitionPath = "/dev/disk/by-partlabel/ssd-root";

    # intel gpu drivers
    intel-gpu.enable = true;

    # nvidia drivers
    nvidia = {
      enable = true;
      cudaCapability = "8.6"; # RTX 3060
    };

    # seagate disk management for all drives
    seagate-hdd = {
      enable = true;
      disks = dataDisks ++ parityDisks;
    };

    # smb share
    samba.enable = true;

    # ssh server
    sshd.enable = true;

    # UPS monitoring
    ups.enable = true;

    # wake on LAN support
    wake-on-lan = {
      enable = true;
      device = "enp2s0";
    };

    # zfs-related services
    zfs.enable = true;
  };
  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
