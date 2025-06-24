# Configuration for icicle (Framework Laptop 13 AMD 7040 series)

{
  inputs,
  lib,
  ...
}:
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # hardware-specific optimizations
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd

    # disks
    (import (lib.custom.relativeToRoot "system/common/disks/boot_drive_luks_interactive.nix") {
      inherit lib;
      device = "/dev/disk/by-id/nvme-nvme.1c5c-414442394e37303139313037303951304f-5348475033312d32303030474d-00000001";
      swapSize = "40G"; # 32G RAM + some extra. not scientific
    })

    # users
    (map (lib.custom.relativeTo "system/common/users/") [
      "parthiv.nix"
    ])

    # required system modules
    (lib.custom.relativeToRoot "system/common/required")
  ];

  networking.hostName = "icicle";

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  # enable desktop environment
  custom = {
    desktop = {
      enable = true;
      # TODO: make this work
      idleMinutes = {
        lock = 1;
        screenOff = 2;
        suspend = 3;
      };
    };

    wifi = {
      enable = true;
      driver = "mt7921e";
    };
  };

  time.timeZone = "America/Los_Angeles";

  # should not be changed until a clean install

  system.stateVersion = "24.11";
}
