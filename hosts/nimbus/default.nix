# Unified configuration for nimbus (Oracle Cloud ARM server)

{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    (lib.custom.relativeToRoot "system/common/modules/selfhosted")
  ];

  networking.hostName = "nimbus";
  time.timeZone = "Etc/UTC";

  # Use GRUB boot loader (required for Oracle Cloud)
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
    loader.efi.canTouchEfiVariables = true;
  };

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
    };

    features = {
      apps.opencode.enable = true;

      meta = {
        impermanence.rootPartitionPath = "/dev/root_vg/root";
        sops.sopsFile = "nimbus.yaml";
      };
    };
  };

  # Should not be changed until a clean install
  system.stateVersion = "24.11";
}
