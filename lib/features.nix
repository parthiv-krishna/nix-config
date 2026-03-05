{ lib, customLib, ... }:
rec {
  # mkFeature: Create a feature module that works in both NixOS and standalone home-manager
  #
  # Arguments:
  #   path: list of strings defining the option path, e.g., ["hardware" "bluetooth"]
  #   extraOptions: additional options beyond the auto-generated `enable`
  #   systemConfig: function (cfg: moduleArgs: { ... }) returning NixOS config
  #   homeConfig: function (cfg: moduleArgs: { ... }) returning home-manager config
  #   homeImports: list of paths to import in the home module (for complex features like nixvim)
  #   nixosExtraConfig: unconditional NixOS config (not wrapped in mkIf cfg.enable)
  mkFeature =
    {
      path,
      # extraOptions can be an attrset or a function (pkgs: { ... })
      extraOptions ? { },
      systemConfig ? null,
      homeConfig ? null,
      homeImports ? [ ],
      nixosExtraConfig ? { },
    }:
    let
      optionPath = [
        "custom"
        "features"
      ]
      ++ path;
      featureName = lib.concatStringsSep "." path;

      mkOptionsDef =
        pkgs:
        {
          enable = lib.mkEnableOption "the ${featureName} feature";
        }
        // (if lib.isFunction extraOptions then extraOptions pkgs else extraOptions);
    in
    {
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }@moduleArgs:
        let
          cfg = lib.getAttrFromPath optionPath config;
          optionsDef = mkOptionsDef pkgs;
        in
        {
          options = lib.setAttrByPath optionPath optionsDef;

          config = lib.mkMerge [
            nixosExtraConfig
            (
              if homeConfig != null || homeImports != [ ] then
                {
                  home-manager.sharedModules = [
                    (
                      {
                        lib,
                        pkgs,
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
                        options = lib.setAttrByPath optionPath (mkOptionsDef pkgs);
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
          pkgs,
          ...
        }@moduleArgs:
        let
          cfg = lib.getAttrFromPath optionPath config;
          optionsDef = mkOptionsDef pkgs;
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

  # mkSelfHostedFeature: Create a selfhosted service feature
  #
  # This creates a feature at custom.features.selfhosted.<name> that:
  # - Registers metadata (homepage, oidcClient) always (for cross-machine config)
  # - Only runs the actual service when enabled on the current host
  #
  # Arguments:
  #   name: service name (also used for option path)
  #   subdomain: subdomain for reverse proxy (defaults to name)
  #   port: service port
  #   extraOptions: additional options beyond `enable`
  #   serviceConfig: function (cfg: moduleArgs: { ... }) returning NixOS service config
  #   homepage: optional { category, description, icon } for homepage dashboard
  #   oidcClient: optional OIDC client config for Authelia
  #   backupServices: list of systemd services to stop during backups
  #   persistentDirectories: directories to persist (for impermanence)
  #   extraConfig: additional NixOS config to merge (always applied when enabled)
  mkSelfHostedFeature =
    {
      name,
      subdomain ? name,
      port,
      extraOptions ? { },
      serviceConfig ? _cfg: _moduleArgs: { },
      homepage ? null,
      oidcClient ? null,
      backupServices ? [ ],
      persistentDirectories ? [ ],
      extraConfig ? { },
    }:
    mkFeature {
      path = [
        "selfhosted"
        name
      ];
      inherit extraOptions;

      # Unconditional config: homepage/oidc entries visible to all hosts
      nixosExtraConfig = lib.mkMerge [
        (lib.optionalAttrs (homepage != null) {
          custom.features.selfhosted.homepageServices.${name} = {
            inherit (homepage) category description icon;
            inherit name subdomain;
            status = homepage.status or null;
          };
        })
        (lib.optionalAttrs (oidcClient != null) {
          custom.features.selfhosted.oidcClients.${name} = oidcClient // {
            inherit subdomain;
          };
        })
      ];

      systemConfig =
        cfg:
        { config, lib, ... }@moduleArgs:
        let
          currentHost = config.networking.hostName;

          fqdn = {
            internal = lib.custom.mkInternalFqdn config.constants subdomain currentHost;
            public = lib.custom.mkPublicFqdn config.constants subdomain;
          };

          virtualHostConfig = logName: {
            logFormat = ''
              output file ${config.services.caddy.logDir}/access-${logName}.log {
                roll_size 10MB
                roll_keep 5
                roll_keep_for 14d
                mode 0640
              }
              level DEBUG
            '';
            extraConfig = ''
              tls {
                dns cloudflare {env.CF_API_TOKEN}
              }
              reverse_proxy localhost:${toString port}
            '';
          };

          persistentDirConfigs = map (
            dir: customLib.custom.mkPersistentSystemDir (if lib.isString dir then { directory = dir; } else dir)
          ) persistentDirectories;
        in
        lib.mkMerge (
          [
            (serviceConfig cfg moduleArgs)
            {
              custom.features.selfhosted.enableReverseProxy = true;
              services.caddy.virtualHosts = {
                "${fqdn.internal}" = virtualHostConfig fqdn.internal;
                "${fqdn.public}" = virtualHostConfig fqdn.public;
              };
            }
            extraConfig
          ]
          ++ persistentDirConfigs
          ++ (lib.optional (backupServices != [ ]) {
            custom.features.selfhosted.backupServices = backupServices;
          })
        );
    };
}
