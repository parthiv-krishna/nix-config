# home-manager config for parthiv@midnight

{
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
    ./common/required
  ];

  home.stateVersion = "24.11";

  # ctrl-b to avoid conflict with client ctrl-a
  programs.tmux.shortcut = lib.mkForce "b";

  home.persistence."/persist/home/parthiv" = {
    directories = [
      ".ssh"
      "nix-config"
    ];
    allowOther = true;
  };
}
