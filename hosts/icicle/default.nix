# Configuration for icicle (Framework Laptop 13 AMD 7040 series)
{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    # hardware-specific optimizations
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];

  networking.hostName = "icicle";

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "America/Los_Angeles";

  custom = {
    manifests = {
      required.enable = true;
      desktop-environment.enable = true;
      laptop.enable = true;
      sound-engineering.enable = true;
    };

    features = {
      apps.opencode.enable = true;

      hardware = {
        audio = {
          enable = true;
          micVolume = 0.25;
        };
        bluetooth.enable = true;
        gpu.amd.enable = true;
        wifi = {
          enable = true;
          driver = "mt7921e";
        };
      };

      desktop.hyprland.idleMinutes = {
        lock = 5;
        screenOff = 6;
        suspend = 10;
      };

      meta = {
        impermanence = {
          rootPartitionPath = "/dev/root_vg/root";
          encryptedDevice = true;
        };
        sops.sopsFile = "icicle.yaml";
      };

      storage.restic.snapshotType = "btrfs";
    };
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
