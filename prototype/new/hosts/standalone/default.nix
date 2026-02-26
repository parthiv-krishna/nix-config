# Standalone home-manager configuration (non-NixOS)
{ ... }:
{
  home.username = "testuser";
  home.homeDirectory = "/home/testuser";
  home.stateVersion = "24.11";

  # Enable features directly (no manifests in standalone mode)
  custom.features = {
    apps.git.enable = true;
    apps.bash.enable = true;
    # Desktop features are NOT enabled on standalone (no GUI)
  };
}
