# Configuration for nimbus (Oracle Cloud server)
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  networking.hostName = "nimbus";
  time.timeZone = "Etc/UTC";

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
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

      selfhosted = {
        enable = true;

        gatus.enable = true;
        grafana.enable = true;
        homepage.enable = true;
        prometheus.enable = true;
        prometheus-blackbox.enable = true;
        prometheus-caddy.enable = true;
        prometheus-node.enable = true;
        prometheus-systemd.enable = true;
        vaultwarden.enable = true;
      };

      storage.restic = {
        backupTime = "11:00"; # 4am PT
        snapshotType = "btrfs";
      };
    };
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
