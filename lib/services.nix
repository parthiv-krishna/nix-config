{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
{
  mkCompose =
    { name, src }:
    let
      generated = pkgs.stdenv.mkDerivation {
        inherit name src;
        buildInputs = [ inputs.compose2nix.packages.${system}.default ];

        buildPhase = ''
          mkdir -p build
          compose2nix -project=${name} -inputs=$src/compose.yml -output=compose.nix
        '';

        installPhase = ''
          mkdir -p $out
          cp $src/* $out
          cp compose.nix $out
        '';
      };
    in
    {
      imports = [ "${generated}/compose.nix" ];
    };

  mkServiceUser =
    {
      serviceName,
      userName ? serviceName,
      dirName ? serviceName,
    }:
    let
      home = "/var/lib/${dirName}";
      log = "/var/log/${dirName}";
    in
    {
      options = {
        user = lib.mkOption {
          type = lib.types.str;
          internal = true;
          readOnly = true;
          default = userName;
        };
        group = lib.mkOption {
          type = lib.types.str;
          internal = true;
          readOnly = true;
          default = userName;
        };
        home = lib.mkOption {
          type = lib.types.str;
          internal = true;
          readOnly = true;
          default = home;
        };
      };

      config = {
        users.users.${userName} = {
          isSystemUser = true;
          group = userName;
          inherit home;
          createHome = true;
        };

        users.groups.${userName} = { };

        systemd.tmpfiles.rules = [
          "d ${home} 0750 ${userName} ${userName} - -"
        ];

        systemd.services.${serviceName}.serviceConfig = {
          User = userName;
          DynamicUser = lib.mkForce false;
          Group = userName;
          StateDirectory = dirName;
        };

        environment.persistence."/persist/system".directories = [
          {
            directory = home;
            user = userName;
            group = userName;
            mode = "0750";
          }
          {
            directory = log;
            user = userName;
            group = userName;
            mode = "0750";
          }
        ];
      };
    };
}
