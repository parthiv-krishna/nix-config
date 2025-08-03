{
  lib,
  ...
}@args:
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

  # cannot use imports = scanPaths ./.; as this is not a nixos module
  filesToImport = scanPaths ./.;
  # load attribute set from each file
  importedAttrsList = builtins.map (
    filePath:
    let
      moduleFunction = import filePath;
    in
    assert lib.isFunction moduleFunction;
    moduleFunction args
  ) filesToImport;
  # merge into one attribute set
  mergedImportedAttrs = lib.foldl lib.recursiveUpdate { } importedAttrsList;
in
{
  custom = {
    inherit scanPaths;
  }
  // mergedImportedAttrs;
}
