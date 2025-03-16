# Configuration for midnight (home server)

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import ./disko.nix { device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_25033U803116"; })
    ./impermanence.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "midnight"; # Define your hostname.

  time.timeZone = "Etc/UTC";

  users.mutableUsers = false;
  users.users.root.hashedPassword = "*"; # no root password
  users.users.parthiv = {
    isNormalUser = true;
    initialHashedPassword = "[redacted]";
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    git
    nixfmt-rfc-style
    tmux
    vim
    wget
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.11";
}
