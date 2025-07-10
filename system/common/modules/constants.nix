{ lib, ... }:
let
  mkConstant =
    type: value:
    lib.mkOption {
      inherit type;
      default = value;
      readOnly = true;
    };
  mkStringConstant = mkConstant lib.types.str;
in
{
  options.constants = {

    proxyHostName = mkStringConstant "nimbus";

    domains = {
      public = mkStringConstant "sub0.net";
      internal = mkStringConstant "ts.sub0.net";
    };
    tieredCache = {
      cachePool = mkStringConstant "/array/merge/cache";
      basePool = mkStringConstant "/array/merge/base";
    };
  };
}
