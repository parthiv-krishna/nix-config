{ lib }:
let
  inherit (import ../../../lib/domains.nix { }) mkInternalFqdn;

  domains = {
    public = "sub0.net";
    internal = "ts.sub0.net";
  };

  systems = {
    x86 = "x86_64-linux";
    arm = "aarch64-linux";
    mac = "aarch64-darwin";
  };

  tags = {
    client = "client";
    server = "server";
  };

  mkHost =
    {
      name,
      system,
      tags,
    }:
    {
      inherit name system tags;
      fqdn = mkInternalFqdn { inherit domains; } "" name;
    };

  values = {
    inherit systems tags domains;

    hosts = {
      honeycrisp = mkHost {
        name = "honeycrisp";
        system = systems.mac;
        tags = [ tags.client ];
      };
      stratus = mkHost {
        name = "stratus";
        system = systems.x86;
        tags = [ tags.server ];
      };
      icicle = mkHost {
        name = "icicle";
        system = systems.x86;
        tags = [ tags.client ];
      };
      midnight = mkHost {
        name = "midnight";
        system = systems.x86;
        tags = [ tags.server ];
      };
      nimbus = mkHost {
        name = "nimbus";
        system = systems.arm;
        tags = [ tags.server ];
      };
    };

    homepage.categories = {
      media = "Media";
      storage = "Storage";
      tools = "Tools";
      network = "Network";
      media-management = "Media Management";
    };
  };

  mkConstant =
    type: value:
    lib.mkOption {
      inherit type;
      default = value;
      readOnly = true;
    };

  wrapAsOption =
    value:
    if builtins.isString value then
      mkConstant lib.types.str value
    else if builtins.isInt value then
      mkConstant lib.types.int value
    else if builtins.isList value then
      mkConstant (lib.types.listOf lib.types.str) value
    else if builtins.isAttrs value then
      lib.mapAttrs (_: wrapAsOption) value
    else
      throw "Unsupported constant type: ${builtins.typeOf value}";

  constantsModule = { inputs, ... }: {
    options.constants = wrapAsOption (
      values
      // {
        secrets = import "${inputs.nix-config-secrets}/constants.nix";
      }
    );
  };
in
{
  inherit values;
  nixos = constantsModule;
  darwin = constantsModule;
  home = constantsModule;
}
