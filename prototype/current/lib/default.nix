# scanPaths helper for auto-importing modules
{ lib, ... }:
{
  custom = {
    scanPaths =
      dirPath:
      let
        fileAttrs = builtins.readDir dirPath;
        nixFileNames = builtins.attrNames (
          lib.attrsets.filterAttrs (
            name: type: type == "directory" || (lib.strings.hasSuffix ".nix" name && name != "default.nix")
          ) fileAttrs
        );
      in
      builtins.map (name: dirPath + "/${name}") nixFileNames;
  };
}
