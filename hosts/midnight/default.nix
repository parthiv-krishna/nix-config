# Configuration for midnight (home server)
_:
let
  dataDisks = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
  ];
  parityDisks = [ "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE" ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  networking.hostName = "midnight";
  time.timeZone = "Etc/UTC";

  # required for ZFS
  networking.hostId = "746e646d"; # mdnt

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
      media.enable = true;
    };

    features = {
      apps.opencode.enable = true;

      hardware = {
        gpu = {
          intel.enable = true;
          nvidia = {
            enable = true;
            cudaCapability = "8.6"; # RTX 3060
          };
        };
        seagate-hdd = {
          enable = true;
          disks = dataDisks ++ parityDisks;
        };
        ups.enable = true;
        wake-on-lan = {
          enable = true;
          device = "enp2s0";
        };
      };

      meta = {
        # tell impermanence to wipe our ssd-root partition on boot
        impermanence.rootPartitionPath = "/dev/disk/by-partlabel/ssd-root";
        sops.sopsFile = "midnight.yaml";
      };

      selfhosted = {
        enable = true;

        actual.enable = true;
        authelia.enable = true;
        calibre-web-automated.enable = true;
        copyparty.enable = true;
        forgejo.enable = true;
        immich.enable = true;
        kasm.enable = true;
        librechat.enable = true;
        llama-swap.enable = true;
        # mealie.enable = true;
        ocis.enable = true;
        paperless.enable = true;
        prometheus-caddy.enable = true;
        prometheus-node.enable = true;
        prometheus-nut.enable = true;
        prometheus-smartmon.enable = true;
        prometheus-systemd.enable = true;
        prometheus-zfs.enable = true;
        shelfmark.enable = true;
      };

      storage = {
        samba.enable = true;
        zfs.enable = true;
      };
    };
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
