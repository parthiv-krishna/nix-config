# home-manager config for standalone usage on non-NixOS hosts
_: {
  home = {
    username = "parthiv";
    homeDirectory = "/home/parthiv";
    stateVersion = "24.11";
  };

  # for non-NixOS systems, ensure we have basic system integration
  targets.genericLinux.enable = true;

  # let home-manager manage itself
  programs.home-manager.enable = true;

  custom = {
    manifests.required.enable = true;

    features.apps = {
      opencode.enable = true;
      pi.enable = true;
    };
  };
}
