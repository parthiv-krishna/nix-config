# Home config for testhost (NixOS)
{ ... }:
{
  imports = [
    ./common/required
  ];

  custom = {
    gui-apps.enable = true;
    hyprland.enable = true;
  };

  home.stateVersion = "24.11";
}
