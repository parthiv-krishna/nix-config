# home-manager config for standalone usage on non-NixOS hosts
{ username, inputs, ... }:
{
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
  };

  # for non-NixOS systems, ensure we have basic system integration
  targets.genericLinux.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.onedark;

  custom.features.apps = {
    git.enable = true;
    bash.enable = true;
    tmux.enable = true;
    nixvim.enable = true;
    opencode.enable = true;
  };
}
