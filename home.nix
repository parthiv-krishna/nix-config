{ pkgs, inputs, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  home.stateVersion = "24.11";

  home.persistence."/persist/home" = {
    directories = [
      ".ssh"
      "nix-config"
    ];
    allowOther = true;
  };
}
