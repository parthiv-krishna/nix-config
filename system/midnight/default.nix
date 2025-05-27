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
    (import (lib.custom.relativeToRoot "system/common/disks/boot_drive_external_nix.nix") {
      device = "/dev/disk/by-id/ata-ADATA_SP610_1F1220031635";
      swapSize = "8G";
    })

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
