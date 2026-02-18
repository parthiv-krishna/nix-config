# home-manager config for standalone usage on non-NixOS hosts (like Ubuntu on WSL)

{
  lib,
  username,
  ...
}:

{
  imports = [
    ../manifests/home-shared.nix
    ../manifests/home-required.nix
  ];

  home = {
    inherit username;
    homeDirectory = lib.mkDefault "/home/${username}";
    stateVersion = "24.11";
  };

  # home-manager manages itself
  programs.home-manager.enable = true;

  custom.opencode.enable = true;

  # for non-NixOS systems, ensure we have basic system integration
  targets.genericLinux.enable = true;
}
