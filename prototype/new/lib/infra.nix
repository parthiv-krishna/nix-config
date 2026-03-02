# Infrastructure helpers: mkFeature, mkHost, loadFeatures
{ lib }:
let
  # Helper to set a value at a nested attribute path
  setAttrByPath = path: value: lib.foldr (name: acc: { ${name} = acc; }) value path;

  # Helper to get a value from a nested attribute path
  getAttrByPath = path: attrs: lib.foldl (acc: name: acc.${name}) attrs path;

  # mkFeature: Create a feature module that works in both NixOS and standalone home-manager
  #
  # Arguments:
  #   path: list of strings defining the option path, e.g., ["hardware" "bluetooth"]
  #   extraOptions: additional options beyond the auto-generated `enable`
  #   systemConfig: function (cfg: moduleArgs: { ... }) returning NixOS config
  #   homeConfig: function (cfg: moduleArgs: { ... }) returning home-manager config
  #
  # The cfg argument contains the resolved options (e.g., cfg.enable, cfg.idleMinutes.lock)
  # The moduleArgs argument contains { config, lib, pkgs, ... } from the module system
  mkFeature =
    {
      path,
      extraOptions ? { },
      systemConfig ? null,
      homeConfig ? null,
    }:
    let
      optionPath = [
        "custom"
        "features"
      ]
      ++ path;
      featureName = lib.concatStringsSep "." path;

      optionsDef = {
        enable = lib.mkEnableOption "the ${featureName} feature";
      }
      // extraOptions;
    in
    {
      # NixOS module
      nixos =
        { config, lib, ... }@moduleArgs:
        let
          cfg = getAttrByPath optionPath config;
        in
        {
          options = setAttrByPath optionPath optionsDef;

          config = lib.mkIf cfg.enable (
            lib.mkMerge [
              (if systemConfig != null then systemConfig cfg moduleArgs else { })
              (
                if homeConfig != null then
                  {
                    home-manager.sharedModules = [
                      (
                        hmArgs:
                        {
                          config = homeConfig cfg hmArgs;
                        }
                      )
                    ];
                  }
                else
                  { }
              )
            ]
          );
        };

      # Home-manager module (for standalone mode)
      home =
        { config, lib, ... }@moduleArgs:
        let
          cfg = getAttrByPath optionPath config;
        in
        {
          options = setAttrByPath optionPath optionsDef;

          config = lib.mkIf cfg.enable (if homeConfig != null then homeConfig cfg moduleArgs else { });
        };
    };

  # loadFeatures: Recursively load all features from a directory in the specified mode
  # Note: customLib must be passed in since we need the fully extended lib with lib.custom
  loadFeatures =
    {
      path,
      mode,
      customLib,
    }:
    let
      # Recursively find all .nix files (excluding default.nix)
      findFeatureFiles =
        dir:
        let
          entries = builtins.readDir dir;
          processEntry =
            name: type:
            let
              entryPath = dir + "/${name}";
            in
            if type == "directory" then
              findFeatureFiles entryPath
            else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
              [ entryPath ]
            else
              [ ];
          results = lib.mapAttrsToList processEntry entries;
        in
        lib.flatten results;

      files = findFeatureFiles path;
      # Each file is a function { lib } -> { nixos = ...; home = ...; }
      # We pass customLib so feature files can access lib.custom.mkFeature
      features = map (f: import f { lib = customLib; }) files;
      # Extract the appropriate module from each feature
      modules = map (f: f.${mode}) features;
    in
    {
      imports = modules;
    };
in
{
  inherit mkFeature loadFeatures;
}
