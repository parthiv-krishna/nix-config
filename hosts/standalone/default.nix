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

  # let home-manager manage itself
  programs.home-manager.enable = true;

  colorScheme = inputs.nix-colors.colorSchemes.onedark;

  custom = {
    manifests.required.enable = true;

    features.apps.opencode.enable = true;
  };
}
