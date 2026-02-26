# testhost system configuration
{ lib, ... }:
{
  imports = lib.flatten [
    ../common/required
  ];

  networking.hostName = "testhost";

  # Enable optional modules
  custom = {
    bluetooth.enable = true;
    desktop = {
      enable = true;
      idleMinutes = {
        lock = 10;
        screenOff = 15;
      };
    };
  };

  # Minimal boot config for evaluation
  boot.loader.grub.device = "nodev";
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  system.stateVersion = "24.11";
}
