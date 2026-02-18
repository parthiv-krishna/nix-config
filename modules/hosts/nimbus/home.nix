# home-manager config for parthiv@nimbus

_: {
  imports = [
    ../../manifests/home-required.nix
  ];

  custom = {
    opencode.enable = true;

    sops.sopsFile = "nimbus.yaml";
  };

  home.stateVersion = "24.11";
}
