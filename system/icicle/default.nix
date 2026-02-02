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
    ./disks.nix

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
    audio = {
      enable = true;
      micVolume = 0.5;
    };

    bluetooth.enable = true;

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
