# Read-only constants feature - MERGE (system and home)
{ lib }:
let
  pureConstants = import ../../../constants.nix;

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
    else if builtins.isList value then
      mkConstant (lib.types.listOf lib.types.str) value
    else if builtins.isAttrs value then
      lib.mapAttrs (_: wrapAsOption) value
    else
      throw "Unsupported constant type: ${builtins.typeOf value}";
in
lib.custom.mkFeature {
  path = [ "meta" "constants" ];

  systemConfig = cfg: { ... }: {
    options.constants = wrapAsOption pureConstants;
  };

  homeConfig = cfg: { ... }: {
    options.constants = wrapAsOption pureConstants;
  };
}
