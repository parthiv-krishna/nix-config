# Extract key home-manager configuration values for comparison
{ config }:
{
  # Home identity
  homeDirectory = config.home.homeDirectory or null;
  username = config.home.username or null;
  inherit (config.home) stateVersion;

  # Custom options
  custom = config.custom or { };

  # Programs
  programs = {
    git.enable = config.programs.git.enable or false;
    bash.enable = config.programs.bash.enable or false;
    kitty.enable = config.programs.kitty.enable or false;
    waybar.enable = config.programs.waybar.enable or false;
  };

  # Wayland
  wayland = {
    windowManager.hyprland.enable = config.wayland.windowManager.hyprland.enable or false;
  };

  # Services
  services = {
    dunst.enable = config.services.dunst.enable or false;
  };
}
