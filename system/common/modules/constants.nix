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
  hosts = {
    icicle = mkStringConstant "icicle";
    midnight = mkStringConstant "midnight";
    nimbus = mkStringConstant "nimbus";
  };
in
{
  options.constants = {
    inherit hosts;

    servers = [
      hosts.midnight
      hosts.nimbus
    ];

    publicServerHost = hosts.nimbus;

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
