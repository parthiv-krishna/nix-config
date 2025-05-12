{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
{
  # use path relative to the root of the project

  # from https://github.com/EmergentMind/nix-config/blob/dev/lib/default.nix
  relativeToRoot = lib.path.append ../.;
  relativeTo = dir: lib.path.append (lib.path.append ../. dir);
  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );

  # derivation to make a nix configuration from a compose.yml
  mkCompose =
    { name, src }:
    let
      generated = pkgs.stdenv.mkDerivation {
        inherit name src;
        buildInputs = [ inputs.compose2nix.packages.${system}.default ];

        # run compose2nix to generate required output file
        buildPhase = ''
          mkdir -p build
          compose2nix -project=${name} -inputs=$src/compose.yml -output=compose.nix
        '';

        # add generated output to expected $out directory
        # then copy the extraConfigFiles to $out as well
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

  # create a service user with persistent state directory
  # the generated user, group, and home can be accessed at
  # config.user, config.group, and config.home
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
