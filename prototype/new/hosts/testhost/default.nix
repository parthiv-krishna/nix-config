# testhost configuration - NixOS host
{ lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  networking.hostName = "testhost";

  # Enable manifests and configure features
  custom = {
    manifests = {
      required.enable = true;
      desktop.enable = true;
    };

    features = {
      desktop.hyprland.idleMinutes = {
        lock = 10;
        screenOff = 15;
      };
    };
  };

  # User setup
  users.users.testuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # Home-manager integration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.testuser = {
      home.stateVersion = "24.11";
    };
    backupFileExtension = "bak";
  };

  system.stateVersion = "24.11";
}
