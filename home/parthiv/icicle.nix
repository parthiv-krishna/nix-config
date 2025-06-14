# home-manager config for parthiv@midnight

{
  ...
}:

{
  imports = [
    ./common/required
    ./common/optional/hyprland
  ];

  home.stateVersion = "24.11";
}
