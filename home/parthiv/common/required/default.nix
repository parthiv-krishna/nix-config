{
  pkgs,
  ...
}:
{
  imports = [
    ./bash.nix
    ./git.nix
    ./sops.nix
    ./tmux.nix
  ];

  home.packages = with pkgs; [
    curl
    fastfetch
    htop
    nixfmt-rfc-style
    pciutils
    trash-cli
    unzip
    usbutils
    wget
    zip
  ];
}
