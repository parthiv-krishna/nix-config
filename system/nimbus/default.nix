# Configuration for nimbus (Oracle Cloud server)

{
  helpers,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    (import (helpers.relativeToRoot "system/common/disks/boot_drive.nix") {
      device = "/dev/sda";
      swapSize = "8G";
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
    ])
  ];

  networking.hostName = "nimbus";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
