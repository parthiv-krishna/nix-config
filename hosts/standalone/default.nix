{ username, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  targets.genericLinux.enable = true;

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
