# home-manager config for parthiv@midnight

_:

{
  imports = [
    ./common/required
  ];

  custom = {
    ai-tools.enable = true;
    sops.sopsFile = "midnight.yaml";
  };

  home.stateVersion = "24.11";
}
