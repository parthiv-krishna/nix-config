# Read-only constants - plain module (not a feature, always loaded)
# This defines options at `options.constants`, not under `custom.features`
# Constants should always be available, not conditional on an enable flag
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

  # Plain module that just defines options.constants
  constantsModule = { lib, ... }: {
    options.constants = wrapAsOption pureConstants;
  };
in
{
  # Return both nixos and home modules (same module works for both)
  nixos = constantsModule;
  home = constantsModule;
}
