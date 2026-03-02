# User configuration with home-manager integration
{ config, inputs, ... }:
let
  # Get the prototype root directory
  prototypeRoot = ../../..;
in
{
  users.users.testuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };
    sharedModules = [
      (prototypeRoot + "/home/common/modules")
    ];
    users.testuser = import (prototypeRoot + "/home/${config.networking.hostName}.nix");
    backupFileExtension = "bak";
  };
}
