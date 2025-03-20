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
    (helpers.relativeToRoot "system/common/users/parthiv.nix")

    # common system modules
    (map helpers.relativeToRoot [
      "system/common/required"
      "system/common/optional/sshd.nix"
      "system/common/optional/nvidia.nix"
    ])
  ];

  networking.hostName = "midnight"; # Define your hostname.

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

}
