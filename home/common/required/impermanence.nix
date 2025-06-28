# impermanence configuration, should be imported to home-manager

{
  inputs,
  ...
}:

{
  imports = [
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  # bare minimum persistent state
  # other home-manager inputs should specify more persistent state
  home.persistence."/persist/home/parthiv" = {
    directories = [
      ".ssh"
      "nix-config"
      "nix-config-secrets"
    ];
    allowOther = true;
  };
}
