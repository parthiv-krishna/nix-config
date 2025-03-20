# home-manager config for parthiv@midnight

{
  lib,
  ...
}:

{
  imports = [
    ./common/required
  ];

  # ctrl-b to avoid conflict with client ctrl-a
  programs.tmux.shortcut = lib.mkForce "b";
}
