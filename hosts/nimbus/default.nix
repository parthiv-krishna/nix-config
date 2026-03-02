# Configuration for nimbus (Oracle Cloud server)
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    (lib.custom.relativeToRoot "system/common/modules/selfhosted")
  ];

  networking.hostName = "nimbus";
  time.timeZone = "Etc/UTC";

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
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

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
