{ username, inputs, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

  # Set default colorScheme for nixvim (nix-colors is imported at flake level)
  colorScheme = inputs.nix-colors.colorSchemes.onedark;

  custom.features = {
    apps = {
      git.enable = true;
      bash.enable = true;
      tmux.enable = true;
      nixvim.enable = true;
      opencode.enable = true;
    };
  };
}
