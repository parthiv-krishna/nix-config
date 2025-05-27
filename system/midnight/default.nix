# Configuration for midnight (home server)

{
  lib,
  pkgs,
  ...
}:
let
  dataDevices = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGMF"
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZLW2BGTQ"
  ];
  parityDevices = [
    "/dev/disk/by-id/ata-ST14000NM005G-2KG133_ZTM09ETE"
  ];
in
{
  imports = lib.flatten [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # disks
    ./disks.nix
    (import (lib.custom.relativeToRoot "system/common/optional/mergerfs-snapraid.nix") {
      inherit
        dataDevices
        parityDevices
        lib
        pkgs
        ;
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
    # suppress raid warnings
    swraid.mdadmConf = ''
      MAILADDR nobody@nowhere
    '';
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
