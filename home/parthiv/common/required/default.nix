{
  config,
  helpers,
  pkgs,
  ...
}:
{
  imports = [
    ./bash.nix
    ./git.nix
    ./tmux.nix
  ];

  home.packages = with pkgs; [
    curl
    fastfetch
    htop
    nixfmt-rfc-style
    pciutils
    unzip
    usbutils
    wget
    zip
  ];
}
