# Configuration for midnight (home server)

{
  lib,
  pkgs,
  ...
}:
let
  dataDevices = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
  ];
  parityDevices = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE"
  ];
in
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    (import (lib.custom.relativeToRoot "system/common/disks/boot_drive_no_persist.nix") {
      device = "/dev/disk/by-id/ata-ADATA_SP610_1F1220031635";
      swapSize = "8G";
    })
    (import (lib.custom.relativeToRoot "system/common/disks/cached_hdd_array.nix") {
      inherit dataDevices parityDevices lib;
      cacheDevice = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_25033U803116";
      cacheSizeGB = 3726;
    })
    (import (lib.custom.relativeToRoot "system/common/optional/mergerfs-snapraid.nix") {
      inherit
        dataDevices
        parityDevices
        lib
        pkgs
        ;
    })

    # users
    (map (lib.custom.relativeTo "system/common/users/") [
      "parthiv.nix"
    ])

    # required system modules
    (lib.custom.relativeToRoot "system/common/required")

    # optional system modules
    (map (lib.custom.relativeTo "system/common/optional") [
      "intel-gpu.nix"
      "nvidia.nix"
      "sshd.nix"
    ])
    (import (lib.custom.relativeToRoot "system/common/optional/wake-on-lan.nix") {
      inherit pkgs;
      device = "enp2s0";
    })
  ];

  networking.hostName = "midnight";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

  custom.reverse-proxy = {
    enable = true;
    email = "letsencrypt.snowy015@passmail.net";
    cloudflareTokenSecretName = "caddy/cloudflare_dns_token";
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
