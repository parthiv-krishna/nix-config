# Configuration for midnight (home server)

{
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
    ./disks.nix

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

  # required for ZFS
  networking.hostId = "746e646d"; # mdnt

  custom = {
    reverse-proxy = {
      enable = true;
      email = "letsencrypt.snowy015@passmail.net";
      cloudflareTokenSecretName = "caddy/cloudflare_dns_token";
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
      enable = true;
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
