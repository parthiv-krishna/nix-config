{ pkgs, ... }:
{
  imports = [
    ../features/core/bash.nix
    ../features/core/git.nix
    ../features/core/nixvim/default.nix
    ../features/core/tmux.nix
  ];

  home.packages = with pkgs; [
    btop
    curl
    dig
    fastfetch
    fzf
    pciutils
    powertop
    ripgrep
    smartmontools
    trash-cli
    unzip
    usbutils
    wget
    yazi
    zip
  ];
}
