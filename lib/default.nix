{
  lib,
  inputs ? { },
  ...
}:
let
  scanPaths =
    dirPath:
    let
      fileAttrs = builtins.readDir dirPath;
      nixFileNames = builtins.attrNames (
        lib.attrsets.filterAttrs (
          # include all directories and .nix files (except default.nix)
          name: type: type == "directory" || (lib.strings.hasSuffix ".nix" name && name != "default.nix")
        ) fileAttrs
      );
    in
    builtins.map (name: dirPath + "/${name}") nixFileNames;

  # import all lib files, passing customLib so they can use other lib.custom functions
  libFiles = scanPaths ./.;
  importedAttrsList = builtins.map (
    filePath:
    let
      moduleFunction = import filePath;
    in
    assert lib.isFunction moduleFunction;
    moduleFunction { inherit lib customLib; }
  ) libFiles;
  mergedAttrs = lib.foldl lib.recursiveUpdate { } importedAttrsList;

  # lib with custom extensions
  customLib = lib // {
    custom = mergedAttrs // {
      inherit scanPaths inputs;
    };
  };
in
{
  inherit (customLib) custom;
}
