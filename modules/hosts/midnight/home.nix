# home-manager config for parthiv@midnight

_:

{
  imports = [
    ../../manifests/home-required.nix
  ];

  custom = {
    opencode.enable = true;
    sops.sopsFile = "midnight.yaml";
  };

  home.stateVersion = "24.11";
}
