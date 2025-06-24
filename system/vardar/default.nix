# Configuration for vardar (always-on home server)

{
  lib,
  ...
}:
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    (import (lib.custom.relativeToRoot "system/common/disks/boot_drive_external_nix.nix") {
      mainDevice = "/dev/disk/by-id/mmc-H8G4a__0x24d44475";
      nixDevice = "/dev/disk/by-id/usb-_USB_DISK_3.0_070002FD3A23B158-0:0";
      swapSize = "1G";
    })

    # users
    (map (lib.custom.relativeTo "system/common/users/") [
      "parthiv.nix"
    ])

    # required system modules
    (lib.custom.relativeToRoot "system/common/required")
  ];

  networking.hostName = "vardar";

  # work around resource limitations
  nix.settings = {
    auto-optimise-store = true;
    cores = 2;
    max-jobs = 1;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "Etc/UTC";

  custom = {
    reverse-proxy = {
      enable = true;
      email = "letsencrypt.snowy015@passmail.net";
      cloudflareTokenSecretName = "caddy/cloudflare_dns_token";
    };

    sshd.enable = true;
    ups.enable = true;
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
