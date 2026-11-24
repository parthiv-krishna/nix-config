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

  # reduce chance of memory pressure from compiling
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
    };

    features = {
      meta = {
        agent_users = {
          enable = true;
          users.public.groups = [ "systemd-journal" ];
        };
        impermanence.rootPartitionPath = "/dev/root_vg/root";
        sops.sopsFile = "stratus.yaml";
      };

      selfhosted = {
        enable = true;
        harmonia.enable = true;
      };

      services.forgejo-runner = {
        enable = true;
        timeout = "24h";
        extraLabels = [ "cache" ];
      };

      storage.restic.snapshotType = "btrfs";
    };
  };

  time.timeZone = "Etc/UTC";
  system.stateVersion = "25.05";
}
