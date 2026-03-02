# Home config for standalone (non-NixOS)
{ ... }:
{
  imports = [
    ./common/required
  ];

  # On standalone, we might enable fewer things
  custom = {
    gui-apps.enable = false; # No GUI on standalone (e.g., WSL)
    hyprland.enable = false;
  };

  # Required for standalone home-manager
  home.username = "testuser";
  home.homeDirectory = "/home/testuser";

  home.stateVersion = "24.11";
}
