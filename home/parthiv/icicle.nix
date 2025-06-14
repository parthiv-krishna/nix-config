# home-manager config for parthiv@icicle

{
  ...
}:

{
  imports = [
    ./common/required
    ./common/optional/gui-apps
    ./common/optional/hyprland
  ];

  home.stateVersion = "24.11";
}
