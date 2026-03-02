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

  constantsModule = _: {
    options.constants = wrapAsOption pureConstants;
  };
in
{
  nixos = constantsModule;
  home = constantsModule;
}
