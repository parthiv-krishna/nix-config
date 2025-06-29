# home-manager config for parthiv@icicle

{
  ...
}:

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
