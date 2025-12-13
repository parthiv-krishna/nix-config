# home-manager config for parthiv@nimbus

_: {
  imports = [
    ./common/required
  ];

  custom = {
    ai-tools.enable = true;

    sops.sopsFile = "nimbus.yaml";
  };

  home.stateVersion = "24.11";
}
