# Extract key configuration values for comparison
{ config }:
{
  # Host identity
  inherit (config.networking) hostName;

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = config.boot.loader.systemd-boot.enable or false;
      grub.enable = config.boot.loader.grub.enable or false;
    };
  };

  # Users
  users = builtins.mapAttrs (_name: user: {
    isNormalUser = user.isNormalUser or false;
    extraGroups = user.extraGroups or [ ];
  }) (config.users.users or { });

  # Key services
  services = {
    greetd.enable = config.services.greetd.enable or false;
    tailscale.enable = config.services.tailscale.enable or false;
    openssh.enable = config.services.openssh.enable or false;
    blueman.enable = config.services.blueman.enable or false;
    pipewire.enable = config.services.pipewire.enable or false;
  };

  # Hardware
  hardware = {
    bluetooth.enable = config.hardware.bluetooth.enable or false;
  };

  # Programs
  programs = {
    hyprland.enable = config.programs.hyprland.enable or false;
  };

  # Custom options (our module options)
  custom = config.custom or { };

  # Time zone
  timeZone = config.time.timeZone or null;

  # System state version
  inherit (config.system) stateVersion;
}
