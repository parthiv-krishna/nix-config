# Configuration for midnight (home server)

{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    ./disks.nix

    # users
    (map (lib.custom.relativeTo "system/common/users/") [
      "parthiv.nix"
    ])

    # required system modules
    (lib.custom.relativeToRoot "system/common/required")

    # optional system modules
    (map (lib.custom.relativeTo "system/common/optional") [
      "intel-gpu.nix"
      "nvidia.nix"
      "sshd.nix"
    ])
    (import (lib.custom.relativeToRoot "system/common/optional/wake-on-lan.nix") {
      inherit pkgs;
      device = "enp2s0";
    })
  ];

  networking.hostName = "midnight";

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # suppress raid warnings

    # raid setup
    swraid.mdadmConf = ''
      MAILADDR nobody@nowhere
    '';
  };

  # setup cached device on boot
  systemd.services.setup-dmcache = {
    description = "Setup dmcache for /data";
    wantedBy = [ "local-fs-pre.target" ];
    before = [ "local-fs-pre.target" ];
    after = [
      "lvm2-activation.service"
      "systemd-cryptsetup@crypted_array0.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      modprobe dm-cache dm-cache-smq
      udevadm settle
      if [ ! -e /dev/mapper/cached_data ]; then
        CACHE_DATA_SIZE=$(blockdev --getsz /dev/cache_vg/cache_data)
        DATA_SIZE=$(blockdev --getsz /dev/data_vg/data)
        DATA_BLOCK_SIZE=256
        dmsetup create cached_data --table "0 $DATA_SIZE cache /dev/cache_vg/cache_meta /dev/cache_vg/cache_data /dev/data_vg/data $DATA_BLOCK_SIZE 1 writeback default 0"
      fi
    '';
  };

  # Filesystem mount
  fileSystems."/data" = {
    device = "/dev/mapper/cached_data";
    fsType = "btrfs";
    options = [ "noatime" ];
  };

  time.timeZone = "Etc/UTC";

  custom.reverse-proxy = {
    enable = true;
    email = "letsencrypt.snowy015@passmail.net";
    cloudflareTokenSecretName = "caddy/cloudflare_dns_token";
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
