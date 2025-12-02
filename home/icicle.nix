# home-manager config for parthiv@icicle

_:

{
  imports = [
    ./common/required
  ];

  custom = {
    gui-apps.enable = true;
    hyprland.enable = true;
    sound-engineering.enable = true;

    sops.sopsFile = "icicle.yaml";
  };

  home.stateVersion = "24.11";
}
