{ lib }:
let
  # mkFeature: Create a feature module that works in both NixOS and standalone home-manager
  #
  # Arguments:
  #   path: list of strings defining the option path, e.g., ["hardware" "bluetooth"]
  #   extraOptions: additional options beyond the auto-generated `enable`
  #   systemConfig: function (cfg: moduleArgs: { ... }) returning NixOS config
  #   homeConfig: function (cfg: moduleArgs: { ... }) returning home-manager config
  #   homeImports: list of paths to import in the home module (for complex features like nixvim)
  mkFeature =
    {
      path,
      extraOptions ? { },
      systemConfig ? null,
      homeConfig ? null,
      homeImports ? [ ],
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
      nixos =
        {
          config,
          lib,
          ...
        }@moduleArgs:
        let
          cfg = lib.getAttrFromPath optionPath config;
        in
        {
          options = lib.setAttrByPath optionPath optionsDef;

          config = lib.mkMerge [
            (
              if homeConfig != null || homeImports != [ ] then
                {
                  home-manager.sharedModules = [
                    (
                      {
                        lib,
                        osConfig,
                        ...
                      }@hmArgs:
                      let
                        # In NixOS mode, read cfg from osConfig (the NixOS-level config)
                        hmCfg = lib.getAttrFromPath optionPath osConfig;
                      in
                      {
                        imports = homeImports;
                        # Still define options for standalone compatibility
                        options = lib.setAttrByPath optionPath optionsDef;
                        config = lib.mkIf hmCfg.enable (if homeConfig != null then homeConfig hmCfg hmArgs else { });
                      }
                    )
                  ];
                }
              else
                { }
            )
            (lib.mkIf cfg.enable (if systemConfig != null then systemConfig cfg moduleArgs else { }))
          ];
        };

      home =
        {
          config,
          lib,
          ...
        }@moduleArgs:
        let
          cfg = lib.getAttrFromPath optionPath config;
        in
        {
          imports = homeImports;
          options = lib.setAttrByPath optionPath optionsDef;

          config = lib.mkIf cfg.enable (if homeConfig != null then homeConfig cfg moduleArgs else { });
        };
    };

  # loadFeatures: Recursively load all features from a directory
  # Directory with default.nix is treated as single feature, otherwise recurse
  loadFeatures =
    {
      path,
      mode,
      customLib,
    }:
    let
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
              let
                subEntries = builtins.readDir entryPath;
                subHasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
              in
              if subHasDefault then [ (entryPath + "/default.nix") ] else findFeatureFiles entryPath
            else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
              [ entryPath ]
            else
              [ ];
          results = lib.mapAttrsToList processEntry entries;
        in
        lib.flatten results;

      files = findFeatureFiles path;
      inputs = customLib.custom.inputs or { };
      importFeature =
        f:
        let
          fn = import f;
          args = builtins.functionArgs fn;
        in
        if args ? inputs then
          fn {
            lib = customLib;
            inherit inputs;
          }
        else
          fn { lib = customLib; };
      features = map importFeature files;
      modules = map (f: f.${mode}) features;
    in
    {
      imports = modules;
    };
in
{
  inherit mkFeature loadFeatures;
}
