# home-manager config for parthiv@icicle

_:

{
  imports = [
    ../../manifests/home-required.nix
  ];

  custom = {
    opencode.enable = true;
    gui-apps.enable = true;
    hyprland.enable = true;
    sound-engineering.enable = true;

    sops.sopsFile = "icicle.yaml";
  };

  home.stateVersion = "24.11";
}
