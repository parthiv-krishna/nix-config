# Configuration for midnight (home server)

{
  config,
  lib,
  ...
}:
let
  dataDisks = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
  ];
  parityDisks = [ "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE" ];
in
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    (import (lib.custom.relativeToRoot "system/common/disks/boot_drive.nix") {
      inherit lib;
      device = "/dev/disk/by-id/ata-ADATA_SP610_1F1220031635";
      swapSize = "8G";
    })
    (import (lib.custom.relativeToRoot "system/common/disks/cached_hdd_array.nix") {
      inherit lib;
      dataDevices = dataDisks;
      parityDevices = parityDisks;
      cacheDevice = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_25033U803116";
    })

    # required system modules
    (lib.custom.relativeToRoot "system/common/required")
  ];

  networking.hostName = "midnight";

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  time.timeZone = "Etc/UTC";

  custom = {
    reverse-proxy = {
      enable = true;
      email = "letsencrypt.snowy015@passmail.net";
      cloudflareTokenSecretName = "caddy/cloudflare_dns_token";
    };

    # tiered cache storage system
    tiered-cache = {
      enable = true;
      cacheDevice = "/array/disk/cache";
      dataDevices = [
        "/array/disk/data0"
        "/array/disk/data1"
      ];
      parityDevices = [
        "/array/disk/parity0"
      ];
      cacheMountPoint = config.constants.tieredCache.cachePool;
      baseMountPoint = config.constants.tieredCache.basePool;
      targetCacheUsage = 80;
      timerSchedule = "Sun *-*-* 07:00";
      webhookSecretName = "tiered-cache/webhook";
      resticRepositories = [ "digitalocean" ];
      aiSummary = {
        enable = true;
        model = "qwen3:30b-a3b";
      };
    };

    # seagate spindown for all drives
    seagate-spindown = {
      enable = true;
      disks = dataDisks ++ parityDisks;
    };

    # ssh server
    sshd.enable = true;

    # wake on LAN support
    wake-on-lan = {
      enable = true;
      device = "enp2s0";
    };

    # nvidia drivers
    nvidia = {
      enable = false;
      cudaCapability = "8.6"; # RTX 3060
    };

    # intel gpu drivers
    intel-gpu.enable = true;

    # UPS monitoring
    ups.enable = true;
  };
  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
