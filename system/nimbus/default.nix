# Configuration for nimbus (Oracle Cloud server)

{
  lib,
  ...
}:
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    (import (lib.custom.relativeToRoot "system/common/disks/boot_drive.nix") {
      device = "/dev/sda";
      swapSize = "8G";
    })

    # required system modules
    (lib.custom.relativeToRoot "system/common/required")
  ];

  networking.hostName = "nimbus";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

  custom = {
    reverse-proxy = {
      enable = true;
      publicFacing = true;
      email = "letsencrypt.snowy015@passmail.net";
      cloudflareTokenSecretName = "caddy/cloudflare_dns_token";
    };

    sshd.enable = true;
  };

  # should not be changed until a clean install
  system.stateVersion = "24.11";
}
