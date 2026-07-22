{ ... }:
{
  imports = [
    ./disks.nix
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "stratus";
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
    };

    features = {
      meta = {
        impermanence.rootPartitionPath = "/dev/root_vg/root";
        sops.sopsFile = "stratus.yaml";
      };

      selfhosted = {
        enable = true;
        buildbot-nix.enable = true;
        harmonia.enable = true;
      };

      storage.restic.snapshotType = "btrfs";
    };
  };

  time.timeZone = "Etc/UTC";
  system.stateVersion = "25.05";
}
