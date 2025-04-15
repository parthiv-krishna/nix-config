# Configuration for midnight (home server)

{
  helpers,
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
    (import (helpers.relativeToRoot "system/common/disks/boot_drive.nix") {
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_25033U803116";
    })
    (import (helpers.relativeToRoot "system/common/disks/hdd_array.nix") {
      devices = dataDevices ++ parityDevices;
    })
    (import (helpers.relativeToRoot "system/common/optional/mergerfs-snapraid.nix") {
      inherit
        dataDevices
        parityDevices
        lib
        pkgs
        ;
    })

    # users
    (map (helpers.relativeTo "system/common/users/") [
      "parthiv.nix"
    ])

    # required system modules
    (helpers.relativeToRoot "system/common/required")

    # optional system modules
    (map (helpers.relativeTo "system/common/optional") [
      "nvidia.nix"
      "sshd.nix"
    ])

    # containers
    (map (helpers.relativeTo "system/common/optional/containers") [
      "actual"
      "authelia"
      "helloworld"
      "traefik"
    ])
  ];

  networking.hostName = "midnight";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
