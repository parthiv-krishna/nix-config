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
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  time.timeZone = "America/Los_Angeles";

  custom = {
    manifests = {
      required.enable = true;
      desktop-environment.enable = true;
      sound-engineering.enable = true;
    };

    features = {
      apps.opencode.enable = true;

      hardware = {
        audio = {
          enable = true;
          micVolume = 0.5;
        };
        bluetooth.enable = true;
        wifi = {
          enable = true;
          driver = "mt7921e";
        };
      };

      desktop.hyprland.idleMinutes = {
        lock = 1;
        screenOff = 2;
        suspend = 3;
      };

      meta = {
        impermanence.rootPartitionPath = "/dev/root_vg/root";
        sops.sopsFile = "icicle.yaml";
      };
    };
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
