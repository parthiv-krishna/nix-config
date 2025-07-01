# home-manager config for parthiv@midnight

_:

{
  imports = [
    ./common/required
  ];

  custom = {
    sops.sopsFile = "midnight.yaml";
  };

  home.stateVersion = "24.11";
}
