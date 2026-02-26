# Extract key configuration values for comparison
{ config }:
{
  # Host identity
  hostName = config.networking.hostName;
  
  # Custom options
  custom = config.custom;
  
  # Key services
  services = {
    greetd.enable = config.services.greetd.enable or false;
    tailscale.enable = config.services.tailscale.enable or false;
    blueman.enable = config.services.blueman.enable or false;
  };
  
  # Hardware  
  hardware = {
    bluetooth.enable = config.hardware.bluetooth.enable or false;
  };
  
  # Programs
  programs = {
    hyprland.enable = config.programs.hyprland.enable or false;
  };
  
  # System state version
  stateVersion = config.system.stateVersion;
}
