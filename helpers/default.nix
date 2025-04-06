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

  # derivation to make a nix configuration from a docker-compose.yml
  mkCompose =
    { name, src }:
    let
      generated = pkgs.stdenv.mkDerivation {
        inherit name src;
        buildInputs = [ inputs.compose2nix.packages.${system}.default ];

        # make a writeable build dir with docker-compose.yml
        # edit the writeable docker-compose.yml to point NIX_DERIVATION_SRC to the $src dir
        # then run compose2nix
        buildPhase = ''
          mkdir -p build
          cp $src/docker-compose.yml build/
          chmod +w build/docker-compose.yml
          substituteInPlace build/docker-compose.yml --replace 'NIX_DERIVATION_SRC' '$src'

          compose2nix -project=${name} -inputs=build/docker-compose.yml -output=build/docker-compose.nix
        '';

        # add generated output to expected $out directory
        installPhase = "mkdir -p $out && cp build/docker-compose.nix $out";
      };
    in
    {
      imports = [ "${generated}/docker-compose.nix" ];
    };

}
