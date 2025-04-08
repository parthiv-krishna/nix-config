# Configuration for midnight (home server)

{
  helpers,
  lib,
  ...
}:

{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    (import (helpers.relativeToRoot "system/common/disks/boot_drive.nix") {
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_25033U803116";
    })

    # users
    (map (helpers.relativeTo "system/common/users/") [
      "parthiv.nix"
    ])

    # required system modules
    (helpers.relativeToRoot "system/common/required")

    # optional system modules
    (map (helpers.relativeTo "system/common/optional") [
      "sshd.nix"
      "nvidia.nix"
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
