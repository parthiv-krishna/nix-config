# Extract key home-manager configuration values for comparison
{ config }:
{
  # Home identity
  homeDirectory = config.home.homeDirectory or null;
  username = config.home.username or null;
  inherit (config.home) stateVersion;

  # Custom options (our module options)
  custom = config.custom or { };

  # Enabled home-manager programs
  programs = {
    git.enable = config.programs.git.enable or false;
    bash.enable = config.programs.bash.enable or false;
    nixvim.enable = config.programs.nixvim.enable or false;
    kitty.enable = config.programs.kitty.enable or false;
    waybar.enable = config.programs.waybar.enable or false;
    wofi.enable = config.programs.wofi.enable or false;
  };

  # Wayland (hyprland)
  wayland = {
    windowManager.hyprland.enable = config.wayland.windowManager.hyprland.enable or false;
  };

  # Services
  services = {
    hypridle.enable = config.services.hypridle.enable or false;
    hyprpaper.enable = config.services.hyprpaper.enable or false;
    dunst.enable = config.services.dunst.enable or false;
  };
}
