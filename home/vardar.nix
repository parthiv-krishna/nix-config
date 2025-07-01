# home-manager config for parthiv@vardar

_: {
  imports = [
    ./common/required
  ];

  custom = {
    sops.sopsFile = "vardar.yaml";
  };

  home.stateVersion = "24.11";
}
